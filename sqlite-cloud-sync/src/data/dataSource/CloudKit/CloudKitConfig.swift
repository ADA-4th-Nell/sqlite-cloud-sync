//
//  CloudKitConfig.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import CloudKit

struct CloudKitConfig {
  private static let container = CKContainer(
    identifier: "iCloud.kr.co.devstory.sqlite-cloud-sync"
  )
  let database: CKDatabase
  let zone: CKRecordZone
  let recordType: String
  let subscriptionId: String

  init(database: CKDatabase, zone: CKRecordZone, recordType: String, subscriptionId: String) {
    self.database = database
    self.zone = zone
    self.recordType = recordType
    self.subscriptionId = subscriptionId
  }

  static func changeset() -> CloudKitConfig {
    let name = ChangesetV1Record.name
    let recordType = "\(ChangesetV1Record.name)_v\(ChangesetV1Record.version)"
    return CloudKitConfig(
      database: CloudKitConfig.container.privateCloudDatabase,
      zone: CKRecordZone(zoneName: name),
      recordType: recordType,
      subscriptionId: recordType
    )
  }
}
