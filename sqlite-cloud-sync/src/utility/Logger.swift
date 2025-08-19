//
//  Logger.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

enum Logger {
  static func d(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
      let fileName = (file as NSString).lastPathComponent
      print("🟢 [DEBUG] \(fileName):\(line) - \(message)")
    #endif
  }

  static func e(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
      let fileName = (file as NSString).lastPathComponent
      print("🔴 [ERROR] \(fileName):\(line) - \(message)")
    #endif
  }

  static func w(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
      let fileName = (file as NSString).lastPathComponent
      print("🟠 [WARNING] \(fileName):\(line) - \(message)")
    #endif
  }
}
