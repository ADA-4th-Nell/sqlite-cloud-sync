//
//  ChangesetData.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

struct ChangesetData {
  let id: String
  let action: ChangesetAction
  let tableName: String
  let oldValues: [String?]
  let newValues: [String?]
  var data: Data
}

extension ChangesetData {
  static func getListFromData(data: Data) throws -> [ChangesetData] {
    var mutableData = data
    return try mutableData.withUnsafeMutableBytes { count, bytes in
      var changes = [ChangesetData]()
      var pIter: OpaquePointer?

      try sqlite3Exec { sqlite3changeset_start(&pIter, count, bytes) }
      defer { sqlite3changeset_finalize(pIter) }

      while SQLITE_ROW == sqlite3changeset_next(pIter) {
        var zTab: UnsafePointer<Int8>?
        var nCol: Int32 = 0
        var op: Int32 = 0
        var pVal: OpaquePointer?

        try sqlite3Exec { sqlite3changeset_op(pIter, &zTab, &nCol, &op, nil) }
        let tableName = String(cString: zTab!)
        var oldValues: [String?] = []
        var newValues: [String?] = []

        if op == SQLITE_UPDATE || op == SQLITE_DELETE {
          for i in 0 ..< nCol {
            try sqlite3Exec { sqlite3changeset_old(pIter, i, &pVal) }
            if let pVal = pVal, let cString = sqlite3_value_text(pVal) {
              oldValues.append(String(cString: cString))
            } else {
              oldValues.append(nil)
            }
          }
        }

        if op == SQLITE_UPDATE || op == SQLITE_INSERT {
          for i in 0 ..< nCol {
            try sqlite3Exec { sqlite3changeset_new(pIter, i, &pVal) }
            if let pVal = pVal, let cString = sqlite3_value_text(pVal) {
              newValues.append(String(cString: cString))
            } else {
              newValues.append(nil)
            }
          }
        }

        let changeId: String =
          switch op {
          case SQLITE_INSERT: newValues[0]!
          default: oldValues[0]!
          }

        let change = ChangesetData(
          id: changeId,
          action: op == SQLITE_INSERT
            ? .insert : op == SQLITE_UPDATE ? .update : .delete,
          tableName: tableName,
          oldValues: oldValues,
          newValues: newValues,
          data: Data(bytes: bytes, count: Int(count))
        )
        changes.append(change)
      }

      return changes
    }
  }
}

extension Data {
  mutating func withUnsafeMutableBytes<ResultType>(
    _ body: (Int32, UnsafeMutableRawPointer) throws -> ResultType
  ) rethrows -> ResultType {
    let count = Int32(count)
    return try withUnsafeMutableBytes { pointer in
      let bytes = pointer.baseAddress!
      return try body(count, bytes)
    }
  }

  func withUnsafeBytes<ResultType>(
    _ body: (Int32, UnsafeRawPointer) throws -> ResultType
  ) rethrows -> ResultType {
    let count = Int32(self.count)
    return try withUnsafeBytes { pointer in
      let bytes = pointer.baseAddress!
      return try body(count, bytes)
    }
  }

  mutating func apply(
    _ sqliteConnection: OpaquePointer,
    bIgnoreConflicts: Bool = true
  )
    throws
  {
    try withUnsafeMutableBytes { count, bytes in
      try sqlite3Exec {
        sqlite3changeset_apply(
          sqliteConnection,
          count, // Size of changeset in bytes
          bytes, // Changeset blob
          nil, // xFilter
          { _, eConflict, _ -> Int32 in
            guard let reason = ConflictReason(rawValue: eConflict) else {
              return ConflictAction.omit.rawValue
            }

            let action: ConflictAction =
              switch reason {
              case .rowDataMismatch: .replace
              case .rowNotFound: .omit
              case .primaryKeyConflict: .omit
              case .constraintViolation: .abort
              case .foreignKeyViolation: .abort
            }
            return action.rawValue
          },
          UnsafeMutableRawPointer(
            mutating: bIgnoreConflicts
              ? UnsafeRawPointer(bitPattern: 1)
              : UnsafeRawPointer(bitPattern: 0)
          )
        )
      }
    }
  }
}
