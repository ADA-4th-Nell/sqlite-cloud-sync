//
//  ConflictReason.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

enum ConflictReason: Int32 {
  /// SQLITE_CHANGESET_DATA
  /// When updating or deleting, the primary key exists but other field values differ from expected
  case rowDataMismatch = 1

  /// SQLITE_CHANGESET_NOTFOUND
  /// When deleting or updating, the row with the specified PK does not exist in the database
  case rowNotFound = 2

  /// SQLITE_CHANGESET_CONFLICT
  /// When inserting, a row with the same PK already exists in the database
  case primaryKeyConflict = 3

  /// SQLITE_CHANGESET_CONSTRAINT
  /// A constraint violation occurs (UNIQUE, CHECK, NOT NULL, etc.)
  case constraintViolation = 4

  /// SQLITE_CHANGESET_FOREIGN_KEY
  /// A foreign key constraint violation occurs
  case foreignKeyViolation = 5
}
