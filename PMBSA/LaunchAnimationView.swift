//
//  LaunchAnimationView.swift
//  PMBSA
//

import SwiftUI

struct LaunchAnimationView: View {
    @Binding var isPresented: Bool

    private let line1 = "You have PMB rights."
    private let line2 = "Know what you're owed."

    @State private var iconVisible = false
    @State private var line1Count = 0
    @State private var line2Count = 0
    @State private var cursorOn = true

    private var line1Done: Bool { line1Count >= line1.count }
    private var line2Done: Bool { line2Count >= line2.count }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1A4A6E), Color(hex: 0x0D2D45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                    .scaleEffect(iconVisible ? 1 : 0.6)
                    .opacity(iconVisible ? 1 : 0)

                VStack(spacing: 8) {
                    typedLine(line1, count: line1Count, color: .white, showCursor: !line1Done && line1Count > 0)
                    typedLine(line2, count: line2Count, color: Color(hex: 0x1ABC9C), showCursor: line1Done && !line2Done)
                }
                .font(.system(size: 24, weight: .bold))
                .frame(minHeight: 70)
            }
            .padding(.horizontal, 32)
        }
        .onAppear(perform: runSequence)
    }

    /// Reveals `text` via a mask rather than swapping substrings, so the underlying
    /// Text view's laid-out size never changes mid-animation — avoids layout reflow/stutter.
    @ViewBuilder
    private func typedLine(_ text: String, count: Int, color: Color, showCursor: Bool) -> some View {
        let fraction = text.isEmpty ? 0 : CGFloat(count) / CGFloat(text.count)
        Text(text)
            .foregroundStyle(color)
            .overlay {
                GeometryReader { geo in
                    Rectangle()
                        .fill(color)
                        .frame(width: 2, height: 22)
                        .opacity(showCursor && cursorOn ? 1 : 0)
                        .position(x: geo.size.width * fraction, y: geo.size.height / 2)
                }
            }
            .mask(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle().frame(width: geo.size.width * fraction)
                }
            }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.2).repeatForever(autoreverses: true)) {
            cursorOn = false
        }

        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                iconVisible = true
            }

            try? await Task.sleep(nanoseconds: 1_450_000_000)
            for i in 1...line1.count {
                line1Count = i
                try? await Task.sleep(nanoseconds: 35_000_000)
            }

            try? await Task.sleep(nanoseconds: 650_000_000)
            for i in 1...line2.count {
                line2Count = i
                try? await Task.sleep(nanoseconds: 35_000_000)
            }

            try? await Task.sleep(nanoseconds: 1_700_000_000)
            withAnimation(.easeOut(duration: 0.45)) {
                isPresented = false
            }
        }
    }
}

private extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#Preview {
    LaunchAnimationView(isPresented: .constant(true))
}
