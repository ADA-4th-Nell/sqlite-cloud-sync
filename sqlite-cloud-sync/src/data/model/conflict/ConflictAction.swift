//
//  ConflictAction.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

/// SQLITE_CHANGESET_OMIT
/// SQLITE_CHANGESET_REPLACE
/// SQLITE_CHANGESET_ABORT
enum ConflictAction: Int32 {
  case omit = 0
  case replace = 1
  case abort = 2
}
