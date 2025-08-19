//
//  ChangesetVersion.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation
import GRDB

struct ChangesetVersion: Codable {
  var deviceId: UUIDDTO
  var pulledAt: Date
}

extension ChangesetVersion: RecordData {
  static var databaseTableName: String = "ChangesetVersion"

  enum CodingKeys: String, CodingKey {
    case deviceId, pulledAt
  }

  enum Columns {
    static let deviceId = Column(CodingKeys.deviceId)
    static let pulledAt = Column(CodingKeys.pulledAt)
  }
}
