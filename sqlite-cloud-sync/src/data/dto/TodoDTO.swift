//
//  TodoDTO.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation
import GRDB

final class TodoDTO {
  let id: UUIDDTO
  let job: String
  let done: Bool
  var updatedAt: Date
  var createdAt: Date

  init(from entity: Todo) {
    self.id = UUIDDTO(entity.id)
    self.job = entity.job
    self.done = entity.done
    self.updatedAt = entity.updatedAt
    self.createdAt = entity.createdAt
  }

  func toEntity() -> Todo {
    return Todo(
      id: id.uuid,
      job: job,
      done: done,
      updatedAt: updatedAt,
      createdAt: createdAt
    )
  }
}

extension TodoDTO: RecordData {
  static var databaseTableName: String = "Todo"

  func willInsert(_: Database) throws {
    if createdAt.timeIntervalSince1970 == 0 {
      createdAt = Date()
    }
    updatedAt = Date()
  }

  func willUpdate(_: Database) throws {
    updatedAt = Date()
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case job
    case done
    case updatedAt
    case createdAt
  }

  enum Columns {
    static let id = Column(CodingKeys.id)
    static let job = Column(CodingKeys.job)
    static let done = Column(CodingKeys.done)
    static let updatedAt = Column(CodingKeys.updatedAt)
    static let createdAt = Column(CodingKeys.createdAt)
  }
}
