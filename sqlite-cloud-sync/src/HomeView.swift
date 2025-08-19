//
//  ContentView.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import SwiftUI

struct HomeView: View {
  @State private var viewModel: HomeViewModel = .init()
  
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
