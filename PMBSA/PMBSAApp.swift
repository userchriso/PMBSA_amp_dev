//
//  PMBSAApp.swift
//  PMBSA
//
//  Created by Chris Olivier on 27/06/2026.
//

import SwiftUI

@main
struct PMBSAApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var showLaunch = true

    var body: some View {
        ZStack {
            ContentView()
            if showLaunch {
                LaunchAnimationView(isPresented: $showLaunch)
                    .transition(.opacity)
            }
        }
    }
}
