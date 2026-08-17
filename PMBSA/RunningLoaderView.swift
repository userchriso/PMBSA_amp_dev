//
//  RunningLoaderView.swift
//  PMBSA
//
//  Loading indicator built from the AmPMBs runner glyph, replacing the generic
//  spinner with a small looping "running" bounce.
//

import SwiftUI

struct RunningLoaderView: View {
    @State private var isStriding = false

    var body: some View {
        Image("RunnerBadge")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .offset(y: isStriding ? -5 : 3)
            .rotationEffect(.degrees(isStriding ? -6 : 6))
            .scaleEffect(x: isStriding ? 1.0 : 0.94, y: isStriding ? 1.0 : 1.05)
            .animation(
                .easeInOut(duration: 0.32).repeatForever(autoreverses: true),
                value: isStriding
            )
            .onAppear { isStriding = true }
            .accessibilityHidden(true)
    }
}
