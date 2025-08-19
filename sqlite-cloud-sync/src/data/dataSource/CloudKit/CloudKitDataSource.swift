//
//  CloudKitDataSource.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import CloudKit
import GRDB

protocol CloudKitDataStorage {
  func setup() async -> Bool
  func reset() async -> Bool
  func push() async
  func pull() async
}

final class CloudKitChangesetDataStorage: CloudKitDataStorage {
  static let shared: CloudKitChangesetDataStorage = .init(
    DatabaseManager.shared,
    CloudKitConfig.changeset()
  )
  private let dbWriter: DatabaseWriter
  private let config: CloudKitConfig
  private let debouncer = Debouncer(delay: 1.0)
  private var isInitialized: Bool
  private var isSetup: Bool
  private var changesetVersion: ChangesetVersion!

  private init(_ dbWriter: DatabaseWriter, _ config: CloudKitConfig) {
    self.config = config
    self.dbWriter = dbWriter
    self.isSetup = false
    self.isInitialized = false

    // Listen pull request
    _ = CloudKitChangesetNotification.listen(mainQueue: false) { event in
      switch event {
      case .push:
        guard self.isInitialized else { return }
        self.debouncer.call {
          Task { await self.push() }
        }
      case .pull:
        guard self.isInitialized else { return }
        self.debouncer.call {
          Task { await self.pull() }
        }
      case .initialize:
        Task {
          if await self.setup() {
            await self.pull()
            await self.push()
          }
          self.isInitialized = true
        }
      case .pushCompleted: break
      case .pullCompleted: break
      }
    }
  }

  // MARK: Setup
  func setup() async -> Bool {
    do {
      if isSetup { return true }
      Logger.d("☁️ Setup: started")
      try await checkAccountStatus()
      try await createZone()
      try await createRecordType()
      try await createSubscription()
      changesetVersion = try await getChangesetVersion()
      isSetup = true
      Logger.d("☁️ Setup: success")
      return true
    } catch {
      Logger.e("☁️ Failed to setup: \(error)")
      return false
    }
  }

  // MARK: Reset
  func reset() async -> Bool {
    do {
      // Delete Subscription
      try await deleteSubscription()

      // Delete Zone
      _ = try await config.database.modifyRecordZones(
        saving: [],
        deleting: [config.zone.zoneID]
      )

      // Update Changeset data pushed=false & pushedAt=nil
      _ = try await dbWriter.write { db in
        try Changeset.updateAll(
          db,
          [
            Changeset.Columns.pushed.set(to: false),
            Changeset.Columns.pushedAt.set(to: nil),
          ]
        )
      }
      // Reset ChangesetVersion pulledAt
      _ = try await dbWriter.write { db in
        try ChangesetVersion.updateAll(
          db,
          [
            ChangesetVersion.Columns.pulledAt.set(
              to: Date(timeIntervalSince1970: 0)
            ),
          ]
        )
      }

      isSetup = false
      Logger.d("☁️ Reset successful")
      return true
    } catch {
      Logger.e("☁️ Failed to reset: \(error)")
      return false
    }
  }

  // MARK: Push
  func push() async {
    do {
      if !isSetup {
        guard await setup() else { return }
      }

      // Fetch changes that have not been uploaded
      let changesets = try await dbWriter.read { db in
        try Changeset.filter(Changeset.Columns.pushed == false).fetchAll(db)
      }

      if changesets.isEmpty {
        Logger.d("☁️ Push: no changes")
        return
      }

      // Convert changeset to record
      let records = changesets.map { changeset in
        let record = CKRecord(
          recordType: config.recordType,
          recordID: CKRecord.ID(
            recordName: changeset.id.uuidString,
            zoneID: config.zone.zoneID
          )
        )

        let deviceId = changesetVersion.deviceId
        let changesetRecord = ChangesetV1Record.from(changeset, deviceId.uuid)
        record.setValuesForKeys(changesetRecord.toMap())
        return record
      }

      // Push
      let result = try await config.database.modifyRecords(
        saving: records,
        deleting: []
      )
      let pushedChangesets: [Changeset] = result.saveResults.compactMap {
        recordID, saveResult in
        let changeset = changesets.first {
          $0.id.uuidString == recordID.recordName
        }
        switch saveResult {
        case .success:
          return changeset
        case let .failure(error):
          let ckError = error as? CKError
          switch ckError?.code {
          case .serverRecordChanged:
            return changeset
          default:
            return nil
          }
        }
      }

      // Update push completion status
      _ = try await dbWriter.write { db in
        try Changeset
          .filter(keys: pushedChangesets.map(\.id))
          .updateAll(
            db,
            [
              Changeset.Columns.pushed.set(to: true),
              Changeset.Columns.pushedAt.set(to: Date()),
            ]
          )
      }

      Logger.d(
        "☁️ Push: success - \(changesets.count)/\(pushedChangesets.count)"
      )
      CloudKitChangesetNotification.pushCompleted.request()
      return
    } catch {
      Logger.e("☁️ Failed to push: \(error)")
      return
    }
  }

  // MARK: Pull
  func pull() async {
    do {
      if !isSetup {
        guard await setup() else { return }
      }
      let deviceId = changesetVersion.deviceId
      let pulledAt = changesetVersion.pulledAt

      // Retrieve Changesets with a difference deviceId and an
      // updatedAt timestamp later than pulledAt.
      let query = CKQuery(
        recordType: config.recordType,
        predicate: NSPredicate(
          format: "%K > %@ AND %K != %@",
          ChangesetV1Record.CodingKeys.uploadedAt.rawValue,
          pulledAt as CVarArg,
          ChangesetV1Record.CodingKeys.deviceId.rawValue,
          deviceId.uuidString
        )
      )
      query.sortDescriptors = [
        NSSortDescriptor(
          key: ChangesetV1Record.CodingKeys.uploadedAt.rawValue,
          ascending: true
        ),
      ]

      let result = try await config.database.records(matching: query)
      if result.matchResults.isEmpty {
        Logger.d("☁️ Pull: no changes")
        return
      }

      for (_, recordResult) in result.matchResults {
        switch recordResult {
        case let .success(record):
          let changesetRecord = ChangesetV1Record.from(record)
          let changeset = changesetRecord.toChangeset()
          let changesetDatas = try ChangesetData.getListFromData(
            data: changeset.data
          )
          for changesetData in changesetDatas {
            switch changeset.action {
            case .insert, .delete:
              try await dbWriter.write { db in
                var mutableData = changesetData
                try mutableData.data.apply(db.sqliteConnection!)
              }
            case .update:
              // Update only if the incoming data's createdAt is more
              // recent than the table's updatedAt.
              let tableName = changeset.tableName
              let changesetCreatedAt = changeset.createdAt
              let localUpdatedAt = try await getUpdatedAt(
                tableName: tableName,
                id: changesetData.id
              )
              if localUpdatedAt < changesetCreatedAt {
                try await dbWriter.write { db in
                  var mutableData = changesetData
                  try mutableData.data.apply(db.sqliteConnection!)
                }
              }
            }

            // Don't record the received changes in the local Changeset table.
            // Instead, update the pulledAt date in ChangesetVersion so that
            // they won’t be fetched again.
            let uploadedAt = changesetRecord.uploadedAt
            try await updateChangesetVersionPulledAt(deviceId, uploadedAt)
            changesetVersion.pulledAt = uploadedAt
          }
        case let .failure(error):
          Logger.e("☁️ Failed to fetch record: \(error)")
        }
      }

      /// Send pull completed notification
      CloudKitChangesetNotification.pullCompleted.request()
      Logger.d("☁️ Pull: success - \(result.matchResults.count)")
      return
    } catch {
      Logger.e("☁️ Failed to pull: \(error)")
      return
    }
  }

  // MARK: Create subscription
  private func createSubscription() async throws {
    let subscription = CKQuerySubscription(
      recordType: config.recordType,
      predicate: NSPredicate(value: true),
      subscriptionID: config.subscriptionId,
      options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
    )

    // Enable background fetch without showing the notification UI.
    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.shouldSendContentAvailable = true
    notificationInfo.alertBody = nil
    notificationInfo.soundName = nil
    notificationInfo.shouldBadge = false
    subscription.notificationInfo = notificationInfo
    try await config.database.save(subscription)
  }
}

extension CloudKitChangesetDataStorage {
  // MARK: Check apple sign in
  private func checkAccountStatus() async throws {
    let status = try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<CKAccountStatus, Error>) in
      CKContainer.default().accountStatus { accountStatus, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: accountStatus)
      }
    }

    if status == .noAccount {
      throw NSError(
        domain: "CloudKit",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No iCloud account found"]
      )
    }
  }

  // MARK: Delete subscription
  private func deleteSubscription() async throws {
    try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Void, Error>) in
      config.database.delete(withSubscriptionID: config.subscriptionId) {
        _,
          error in
        if let error = error {
          Logger.e("Failed to delete subscription: \(error)")
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  // MARK: Create zone
  private func createZone() async throws {
    _ = try await config.database.modifyRecordZones(
      saving: [config.zone],
      deleting: []
    )
  }

  // MARK: Create RecordType
  private func createRecordType() async throws {
    let record = CKRecord(
      recordType: config.recordType,
      recordID: CKRecord.ID(
        recordName: UUID().uuidString,
        zoneID: config.zone.zoneID
      )
    )

    _ = try await config.database.modifyRecords(
      saving: [record],
      deleting: []
    )
  }

  // MARK: Get change version
  private func getChangesetVersion() async throws -> ChangesetVersion {
    return try await dbWriter.read { db in
      try ChangesetVersion.fetchOne(db)
    }!
  }

  // MARK: Get updatedAt by tableName and id
  private func getUpdatedAt(tableName: String, id: String) async throws -> Date {
    return try await dbWriter.read { db in
      let row = try Row.fetchOne(
        db,
        sql: "SELECT updatedAt FROM \(tableName) WHERE id = ?",
        arguments: [id]
      )
      return Date.fromUTCString(row?["updatedAt"])
    }
  }

  // MARK: Update ChangesetVersion pulledAt
  private func updateChangesetVersionPulledAt(
    _ deviceId: UUIDDTO,
    _ pulledAt: Date
  )
    async throws
  {
    _ = try await dbWriter.write { db in
      try ChangesetVersion
        .filter(ChangesetVersion.Columns.deviceId == deviceId)
        .updateAll(
          db,
          [ChangesetVersion.Columns.pulledAt.set(to: pulledAt)]
        )
    }
  }
}
