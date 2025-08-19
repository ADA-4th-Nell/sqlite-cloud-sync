//
//  CloudKitRecord.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

protocol CloudKitRecord {
  static var name: String { get }
  static var version: Int { get }
}
