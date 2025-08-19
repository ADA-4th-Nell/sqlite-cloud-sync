//
//  ContentView.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import SwiftUI

struct HomeView: View {
  init() {
    checkSessionExtension()
  }
  
  func checkSessionExtension() {
    if let checkCString = my_custom_sqlite_build_tag() {
      let check = String(cString: checkCString)
      print("Session Extension Enabled: \(check)")
    }
  }
  
    var body: some View {
        VStack {
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
