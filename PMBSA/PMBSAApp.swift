//
//  PMBSAApp.swift
//  PMBSA
//
//  Created by Chris Olivier on 27/06/2026.
//

import SwiftUI
import UIKit

@main
struct PMBSAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { SplashWindow.shared.present() }
        }
    }
}

/// Shows the launch animation in its own `UIWindow`, layered above the main window (including
/// its navigation bar and toolbar) via real window z-ordering rather than SwiftUI view nesting.
///
/// A SwiftUI overlay placed as a ZStack sibling of `ContentView`, or presented via
/// `.fullScreenCover`, both proved unreliable here: `ContentView`'s `NavigationStack` chrome
/// could still render above a plain ZStack overlay, and a `fullScreenCover`'s content isn't
/// composited live above the presenting view, so fading it to transparent revealed a blank
/// system backdrop instead of crossfading into the app. A separate window with a higher
/// `windowLevel` sidesteps both: it's guaranteed to sit above everything in the main window, and
/// fading it out reveals the main window's already-live content underneath.
@MainActor
final class SplashWindow {
    static let shared = SplashWindow()

    private var window: UIWindow?
    private var hasPresented = false

    private init() {}

    func present() {
        guard !hasPresented, let scene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene else { return }
        hasPresented = true

        let overlayWindow = UIWindow(windowScene: scene)
        overlayWindow.windowLevel = .normal + 1
        overlayWindow.backgroundColor = .clear
        overlayWindow.isHidden = false

        let hostingController = UIHostingController(
            rootView: LaunchAnimationView(onFinished: { [weak self] in self?.dismiss() })
        )
        hostingController.view.backgroundColor = .clear
        overlayWindow.rootViewController = hostingController

        window = overlayWindow
    }

    private func dismiss() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }
}
