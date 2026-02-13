import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.11, blue: 0.22), Color(red: 0.02, green: 0.23, blue: 0.17)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("PIXEL BLACKJACK")
                    .font(.system(size: 46, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Arcade run mode")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                VStack(spacing: 12) {
                    Button("Play") {
                        onPlay()
                    }
                    .buttonStyle(MenuButtonStyle(tint: Color(red: 0.14, green: 0.70, blue: 0.46)))

                    Button("Settings") {
                        onSettings()
                    }
                    .buttonStyle(MenuButtonStyle(tint: Color(red: 0.32, green: 0.56, blue: 0.88)))
                }
                .padding(.top, 8)

                Spacer()

                Text("Single-player. Local save. No monetization.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 28)
        }
    }
}

private struct MenuButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .frame(maxWidth: 320)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.70 : 1.0))
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.30), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
