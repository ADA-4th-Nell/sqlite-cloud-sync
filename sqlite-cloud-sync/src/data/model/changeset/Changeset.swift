//
//  Changeset.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation
import GRDB

final class Changeset: Codable {
  let id: UUIDDTO
  var data: Data
  let action: ChangesetAction
  let tableName: String
  let pushed: Bool
  let pushedAt: Date?
  let createdAt: Date

  init(
    id: UUIDDTO,
    data: Data,
    action: ChangesetAction,
    tableName: String,
    pushed: Bool,
    pushedAt: Date?,
    createdAt: Date
  ) {
    self.id = id
    self.data = data
    self.action = action
    self.tableName = tableName
    self.pushed = pushed
    self.pushedAt = pushedAt
    self.createdAt = createdAt
  }
}

extension Changeset: RecordData {
  static var databaseTableName: String = "Changeset"

  enum CodingKeys: String, CodingKey {
    case id, data, action, tableName, pushed, pushedAt, createdAt
  }

  enum Columns {
    static let id = Column(CodingKeys.id)
    static let data = Column(CodingKeys.data)
    static let action = Column(CodingKeys.action)
    static let tableName = Column(CodingKeys.tableName)
    static let pushed = Column(CodingKeys.pushed)
    static let pushedAt = Column(CodingKeys.pushedAt)
    static let createdAt = Column(CodingKeys.createdAt)
  }
}
