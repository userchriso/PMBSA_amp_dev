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

/// Shows the launch splash, then replaces it with `ContentView` — a plain structural swap in a
/// single view hierarchy, not an overlay.
///
/// Earlier approaches (a ZStack sibling faded over `ContentView`, a `fullScreenCover`, a second
/// `UIWindow` at a higher `windowLevel`) all kept `ContentView` alive and composited against the
/// splash at the same time, across either a view-layer or window-layer boundary. Every one of
/// those surfaced its own compositing artifact right at the handoff — `ContentView`'s chrome
/// bleeding above the splash, or a stale frame of the splash's own reveal animation flashing back
/// after `ContentView` appeared — regardless of what `ContentView`'s chrome was built from. This
/// swap avoids that whole category: `ContentView` doesn't exist until `showSplash` flips to
/// `false`, so there's never a moment where two live things need to be reconciled against each
/// other. `showSplash` is flipped with a plain (unanimated) assignment — an animated cross-fade
/// here previously introduced its own transition artifact.
struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        if showSplash {
            LaunchAnimationView(onFinished: { showSplash = false })
        } else {
            ContentView()
        }
    }
}
