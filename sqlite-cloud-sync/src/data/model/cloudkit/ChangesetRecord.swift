//
//  ChangesetRecord.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import CloudKit
import Foundation

struct ChangesetV1Record: CloudKitRecord {
  static var name: String = "Changeset"
  static var version: Int = 1
  let id: String
  let deviceId: String
  let data: NSData
  let action: Int64
  let tableName: String
  let uploadedAt: Date
  let createdAt: Date
}

extension ChangesetV1Record {
  static func from(_ changeset: Changeset, _ deviceId: UUID) -> ChangesetV1Record {
    ChangesetV1Record(
      id: changeset.id.uuid.uuidString,
      deviceId: deviceId.uuidString,
      data: changeset.data as NSData,
      action: Int64(changeset.action.rawValue),
      tableName: changeset.tableName,
      uploadedAt: Date(),
      createdAt: changeset.createdAt,
    )
  }

  static func from(_ record: CKRecord) -> ChangesetV1Record {
    ChangesetV1Record(
      id: record.recordID.recordName,
      deviceId: record["deviceId"]!,
      data: record["data"]!,
      action: record["action"]!,
      tableName: record["tableName"]!,
      uploadedAt: record["uploadedAt"]!,
      createdAt: record["createdAt"]!,
    )
  }

  enum CodingKeys: String, CodingKey {
    case id, deviceId, data, action, tableName, uploadedAt, createdAt
  }

  func toMap() -> [String: Any] {
    [
      "id": id,
      "deviceId": deviceId,
      "data": data,
      "action": action,
      "tableName": tableName,
      "uploadedAt": uploadedAt,
      "createdAt": createdAt,
    ]
  }

  func toChangeset() -> Changeset {
    Changeset(
      id: .init(UUID(uuidString: id)!),
      data: data as Data,
      action: .init(rawValue: Int(action))!,
      tableName: tableName,
      pushed: true,
      pushedAt: uploadedAt,
      createdAt: createdAt
    )
  }
}
