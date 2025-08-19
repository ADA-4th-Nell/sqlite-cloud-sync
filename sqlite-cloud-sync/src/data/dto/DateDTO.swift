//
//  DateDTO.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import Foundation

extension Date {
  nonisolated static func fromUTCString(_ dateString: String?) -> Date {
    guard let dateString = dateString else {
      return Date(timeIntervalSince1970: 0)
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.date(from: dateString) ?? Date(timeIntervalSince1970: 0)
  }
}
