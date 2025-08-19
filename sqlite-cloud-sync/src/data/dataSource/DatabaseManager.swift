//
//  DatabaseManager.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation
import GRDB

struct DatabaseManager {
  static let shared = makeShared()
  private init() {}

  static func checkSessionExtension() -> Bool {
    if let checkCString = my_custom_sqlite_build_tag() {
      Logger.d(String(cString: checkCString))
      return true
    } else {
      return false
    }
  }

  private static func makeShared() -> DatabaseWriter {
    do {
      guard checkSessionExtension() else {
        fatalError("Session extension is not enabled")
      }

      let fileManager = FileManager.default
      let appSupportURL = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      let directoryURL = appSupportURL.appendingPathComponent(
        "Database",
        isDirectory: true
      )
      try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
      )

      // Open or create the database
      let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
      let dbPool = try DatabasePool(path: databaseURL.path)
      try DatabaseManager.migrate(dbPool)

      Logger.d("📚 Database stored at: \(databaseURL.path)")
      return dbPool
    } catch {
      fatalError("Failed to open database: \(error)")
    }
  }

  private static func migrate(_ dbWriter: DatabaseWriter) throws {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("v1") { db in
      /// Todo
      try db.create(table: "Todo") { t in
        t.column("id", .text).primaryKey()
        t.column("job", .text).notNull()
        t.column("done", .boolean).notNull()
        t.column("updatedAt", .datetime).notNull()
        t.column("createdAt", .datetime).notNull()
      }

      /// Changeset
      try db.create(table: "Changeset") { t in
        t.column("id", .text).primaryKey()
        t.column("data", .blob).notNull()
        t.column("action", .integer).notNull()
        t.column("tableName", .text).notNull()
        t.column("pushed", .boolean).notNull()
        t.column("pushedAt", .datetime)
        t.column("createdAt", .datetime).notNull()
      }

      /// Changeset version
      try db.create(table: "ChangesetVersion") { t in
        t.column("deviceId", .text).primaryKey()
        t.column("pulledAt", .datetime).notNull()
      }

      /// Insert deviceId
      let deviceId = UUID().uuidString
      let pulledAt = Date(timeIntervalSince1970: 0)
      try db.execute(
        sql: "INSERT INTO ChangesetVersion (deviceId, pulledAt) VALUES (?, ?)",
        arguments: [deviceId, pulledAt]
      )
    }
    try migrator.migrate(dbWriter)
  }
}
