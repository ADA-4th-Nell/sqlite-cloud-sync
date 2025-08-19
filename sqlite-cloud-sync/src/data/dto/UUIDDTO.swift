//
//  UUIDDTO.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation
import GRDB

struct UUIDDTO: DatabaseValueConvertible, Equatable, Hashable, Codable {
  let uuid: UUID

  var uuidString: String { uuid.uuidString }

  init(_ uuid: UUID) {
    self.uuid = uuid
  }

  static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UUIDDTO? {
    guard let uuidString = String.fromDatabaseValue(dbValue),
          let uuid = UUID(uuidString: uuidString)
    else {
      return nil
    }
    return UUIDDTO(uuid)
  }

  var databaseValue: DatabaseValue {
    return uuid.uuidString.databaseValue
  }
}
