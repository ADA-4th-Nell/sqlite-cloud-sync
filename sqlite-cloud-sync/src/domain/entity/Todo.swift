//
//  Todo.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

struct Todo: Identifiable {
  let id: UUID
  let job: String
  let done: Bool
  let updatedAt: Date
  let createdAt: Date
}

extension Todo {
  func copyWith(
    id: UUID? = nil,
    job: String? = nil,
    done: Bool? = nil,
    updatedAt: Date? = nil,
    createdAt: Date? = nil
  ) -> Todo {
    return Todo(
      id: id ?? self.id,
      job: job ?? self.job,
      done: done ?? self.done,
      updatedAt: updatedAt ?? self.updatedAt,
      createdAt: createdAt ?? self.createdAt
    )
  }
}
