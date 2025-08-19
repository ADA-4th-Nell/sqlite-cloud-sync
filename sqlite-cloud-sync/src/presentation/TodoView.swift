//
//  TodoView.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import SwiftUI

struct TodoView: View {
  @FocusState private var isFocused: Bool
  @State private var job: String = ""
  @State private var viewModel: TodoViewModel = .init(
    todoRepository: TodoRepository(dataSource: SQLiteSessionDataSource.shared)
  )

  private func create() {
    if job.isEmpty { return }
    viewModel.create(job)
    isFocused = true
    job = ""
  }

  var body: some View {
    Form {
      // MARK: Create Todo

      HStack {
        TextField("Todo", text: $job)
          .focused($isFocused)
          .onSubmit(create)
        Button(action: create) {
          Image(systemName: "plus.circle")
        }
        .frame(width: 44, height: 44)
      }

      // MARK: Todo List

      List {
        ForEach(Array(viewModel.todos.enumerated()), id: \.element.id) {
          index,
            todo in
          HStack {
            // MARK: Done
            Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
              .foregroundColor(todo.done ? .green : .gray)

            // MARK: Job

            Text(todo.job)
            Spacer()
          }
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.update(index)
          }
        }
        .onDelete { offsets in
          for offset in offsets {
            viewModel.delete(offset)
          }
        }
      }
    }
    .onAppear {
      isFocused = true
    }
    .task {
      viewModel.fetch()
      _ = CloudKitChangesetNotification.listen(mainQueue: true) { event in
        if event == .pullCompleted {
          self.viewModel.fetch()
        }
      }
    }
  }
}

#Preview {
  TodoView()
}
