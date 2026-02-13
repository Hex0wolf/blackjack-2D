import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BlackjackViewModel()

    var body: some View {
        Group {
            switch viewModel.activeScreen {
            case .menu:
                MainMenuView(
                    onPlay: { viewModel.startGame() },
                    onSettings: { viewModel.openSettings() }
                )
            case .game:
                GameScreenView(viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.activeScreen)
    }
}

#Preview {
    ContentView()
}
