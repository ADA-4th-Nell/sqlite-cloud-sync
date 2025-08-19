//
//  Debouncer.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

class Debouncer {
  private let queue: DispatchQueue
  private var workItem: DispatchWorkItem?
  private let delay: TimeInterval

  init(delay: TimeInterval, queue: DispatchQueue = .main) {
    self.delay = delay
    self.queue = queue
  }

  func call(_ block: @escaping () -> Void) {
    workItem?.cancel()
    workItem = DispatchWorkItem(block: block)
    if let workItem = workItem {
      queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
  }
}
