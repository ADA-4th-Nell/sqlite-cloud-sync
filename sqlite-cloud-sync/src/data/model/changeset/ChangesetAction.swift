//
//  ChangesetAction.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

enum ChangesetAction: Int, Codable {
  case delete = -1
  case update = 0
  case insert = 1
}
