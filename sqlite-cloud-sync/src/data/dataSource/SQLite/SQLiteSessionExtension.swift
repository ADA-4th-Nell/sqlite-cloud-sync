//
//  SQLiteSessionExtension.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

func sqlite3Exec(operation: () -> Int32) throws {
  let resultCode = operation()
  if resultCode != SQLITE_OK {
    let errmsg = String(cString: sqlite3_errstr(resultCode))
    throw SQLiteError.operationFailed(errmsg)
  }
}

public class SQLiteSessionExtension {
  let session: OpaquePointer

  init(_ sqliteConnection: OpaquePointer) throws {
    // Create session
    var session: OpaquePointer?
    try sqlite3Exec {
      sqlite3session_create(sqliteConnection, "main", &session)
    }
    self.session = session!

    // Attach to all tables
    try sqlite3Exec { sqlite3session_attach(session, nil) }
  }

  deinit {
    sqlite3session_delete(session)
  }

  /// If called a second time on a session object, the changeset will contain all changes that have taken place on the connection since the session was created.
  /// In other words, a session object is not reset or zeroed by a call to sqlite3session_changeset().
  func captureChangesetData() throws -> [ChangesetData]? {
    var bytes: UnsafeMutableRawPointer?
    var count: Int32 = 0
    try sqlite3Exec { sqlite3session_changeset(session, &count, &bytes) }
    if bytes != nil {
      defer { sqlite3_free(bytes) }
      let data = Data(bytes: bytes!, count: Int(count))
      return try ChangesetData.getListFromData(data: data)
    }
    return nil
  }
}
