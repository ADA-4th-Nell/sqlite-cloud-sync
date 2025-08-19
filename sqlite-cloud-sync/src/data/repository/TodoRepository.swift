//
//  TodoRepository.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import GRDB

final class TodoRepository {
  private let dataSource: SQLiteDataSource

  init(dataSource: SQLiteDataSource) {
    self.dataSource = dataSource
  }

  func fetch() -> [Todo] {
    do {
      let dtos = try dataSource.fetchAll(
        TodoDTO.self,
        query: TodoDTO.all().order(
          TodoDTO.Columns.createdAt.asc
        )
      )
      return dtos.map { $0.toEntity() }
    } catch {
      Logger.e("Failed to fetch: \(error)")
      return []
    }
  }

  func insert(_ todo: Todo) -> Todo? {
    do {
      let newDto = TodoDTO(from: todo)
      let dto = try dataSource.insert(newDto)
      return dto.toEntity()
    } catch {
      Logger.e("Failed to insert: \(error)")
      return nil
    }
  }

  func update(_ todo: Todo) -> Todo? {
    do {
      let newDto = TodoDTO(from: todo)
      let dto = try dataSource.update(newDto)
      return dto.toEntity()
    } catch {
      Logger.e("Failed to update: \(error)")
      return nil
    }
  }

  func delete(_ todo: Todo) -> Todo? {
    do {
      let targetDto = TodoDTO(from: todo)
      let dto = try dataSource.delete(targetDto)
      return dto.toEntity()
    } catch {
      Logger.e("Failed to delete: \(error)")
      return nil
    }
  }
}
