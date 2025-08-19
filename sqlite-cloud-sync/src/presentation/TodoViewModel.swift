//
//  TodoViewModel.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import SwiftUI

@Observable
final class TodoViewModel {
  private var todoRepository: TodoRepository
  private(set) var todos: [Todo]

  init(todoRepository: TodoRepository) {
    self.todoRepository = todoRepository
    self.todos = []
  }

  func fetch() {
    todos = todoRepository.fetch()
  }

  func create(_ job: String) {
    if job.isEmpty { return }
    let newTodo = Todo(
      id: UUID(),
      job: job,
      done: false,
      updatedAt: Date(),
      createdAt: Date()
    )
    guard let todo = todoRepository.insert(newTodo) else { return }
    todos.append(todo)
  }

  func update(_ index: Int) {
    let target = todos[index]
    let newTodo = target.copyWith(
      done: !target.done
    )
    guard let todo = todoRepository.update(newTodo) else { return }
    todos[index] = todo
  }

  func delete(_ index: Int) {
    let target = todos[index]
    guard todoRepository.delete(target) != nil else { return }
    todos.remove(at: index)
  }
}
