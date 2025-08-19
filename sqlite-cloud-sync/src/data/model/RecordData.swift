//
//  RecordData.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import GRDB

protocol RecordData: Codable, FetchableRecord, PersistableRecord {}
