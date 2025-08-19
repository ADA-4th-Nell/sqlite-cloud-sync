//
//  SQLiteDataSource.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation
import GRDB

protocol SQLiteDataSource {
  func insert<T: RecordData>(_ record: T) throws -> T
  func update<T: RecordData>(_ record: T) throws -> T
  func delete<T: RecordData>(_ record: T) throws -> T
  func fetch<T: RecordData>(_ id: UUIDDTO) throws -> T
  func fetchAll<T: RecordData>(_ type: T.Type, query: QueryInterfaceRequest<T>?)
    throws -> [T]
}

struct SQLiteSessionDataSource: SQLiteDataSource {
  static let shared: SQLiteDataSource = SQLiteSessionDataSource(
    DatabaseManager.shared,
  )
  private let dbWriter: DatabaseWriter

  private init(_ dbWriter: DatabaseWriter) {
    self.dbWriter = dbWriter
  }

  private func createTableIfNeeded(
    for tableName: String,
    columns: (TableDefinition) -> Void
  ) throws {
    try dbWriter.write { db in
      try db.create(table: tableName, ifNotExists: true, body: columns)
    }
  }

  private func sessionCapture<T>(
    _ db: Database,
    _ updates: (Database) throws -> T
  ) throws -> T {
    guard let sqliteConnection = db.sqliteConnection else {
      fatalError("sqliteConnection is nil")
    }
    
    // 1. Start a session
    let session = try SQLiteSessionExtension(sqliteConnection)

    // 2. Perform the insert & update & delete
    let result = try updates(db)

    // 3. Capture the changeset data
    if let changeDatas = try session.captureChangesetData() {
      for changeData in changeDatas {
        let changeset = Changeset(
          id: UUIDDTO(UUID()),
          data: changeData.data,
          action: changeData.action,
          tableName: changeData.tableName,
          pushed: false,
          pushedAt: nil,
          createdAt: Date()
        )

        try changeset.insert(db)
      }

      // 4. Upload the changeset to cloud
      CloudKitChangesetNotification.push.request()
    }
    return result
  }

  func insert<T: RecordData>(_ record: T) throws -> T {
    do {
      return try dbWriter.write { db in
        try sessionCapture(db) { _ in
          try record.insert(db)
          return record
        }
      }
    } catch {
      Logger.e("insert failure: \(error)")
      throw error
    }
  }

  func fetch<T: RecordData>(_ id: UUIDDTO) throws -> T {
    do {
      return try dbWriter.read { db in
        guard let record = try T.filter(Column("id") == id).fetchOne(db) else {
          throw NSError(
            domain: "SQLiteSessionExtensionDataStorage",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Record not found"]
          )
        }
        return record
      }
    } catch {
      Logger.e("fetch failure: \(error)")
      throw error
    }
  }

  func fetchAll<T: RecordData>(
    _: T.Type,
    query: QueryInterfaceRequest<T>? = nil
  ) throws -> [T] {
    do {
      return try dbWriter.read { db in
        let req = query ?? T.all()
        let record = try req.fetchAll(db)
        return record
      }
    } catch {
      Logger.e("fetchAll failure: \(error)")
      throw error
    }
  }

  func update<T: RecordData>(_ record: T) throws -> T {
    do {
      return try dbWriter.write { db in
        try sessionCapture(db) { _ in
          try record.update(db)
          return record
        }
      }
    } catch {
      Logger.e("update failure: \(error)")
      throw error
    }
  }

  func delete<T: RecordData>(_ record: T) throws -> T {
    do {
      return try dbWriter.write { db in
        try sessionCapture(db) { _ in
          try record.delete(db)
          return record
        }
      }
    } catch {
      Logger.e("hard delete failure: \(error)")
      throw error
    }
  }
}
