//
//  TodoViewModel.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import SwiftUI

@Observable
final class TodoViewModel {
  private(set) var todos: [Todo] = []

  func fetch() {}
  
  func create(_ job: String) {
    if job.isEmpty { return }
    todos.append(
      Todo(
        id: UUID(),
        job: job,
        done: false,
        updatedAt: Date(),
        createdAt: Date()
      )
    )
  }
  
  func update(_ index: Int) {
    let todo = todos[index]
    todos[index] = todo.copyWith(
      done: !todo.done
    )
  }
  
  func delete(_ index: Int) {
    todos.remove(at: index)
  }
}
