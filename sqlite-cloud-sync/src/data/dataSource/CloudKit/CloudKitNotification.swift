//
//  CloudKitNotification.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

extension Notification.Name {
  static let changeset = Notification.Name(
    "CloudKitChangeset"
  )
}

enum CloudKitChangesetNotification: String {
  case initialize
  case push
  case pushCompleted
  case pull
  case pullCompleted

  func request() {
    NotificationCenter.default.post(
      name: .changeset,
      object: nil,
      userInfo: ["event": self]
    )
  }

  static func listen(
    mainQueue: Bool,
    handler: @escaping (CloudKitChangesetNotification) -> Void
  ) -> NSObjectProtocol {
    func getBackgroundQueue() -> OperationQueue {
      let backgroundQueue = OperationQueue()
      backgroundQueue.qualityOfService = .background
      return backgroundQueue
    }
    return NotificationCenter.default.addObserver(
      forName: .changeset,
      object: nil,
      queue: mainQueue
        ? .main : getBackgroundQueue()
    ) { notification in
      guard
        let userInfo = notification.userInfo,
        let event = userInfo["event"] as? CloudKitChangesetNotification
      else { return }
      handler(event)
    }
  }
}

extension NSObjectProtocol {
  func remove() {
    NotificationCenter.default.removeObserver(self)
  }
}
