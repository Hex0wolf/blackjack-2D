import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: BlackjackViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Toggle("Music", isOn: Binding(
                        get: { viewModel.settings.musicEnabled },
                        set: { viewModel.setMusicEnabled($0) }
                    ))
                    Toggle("SFX", isOn: Binding(
                        get: { viewModel.settings.sfxEnabled },
                        set: { viewModel.setSFXEnabled($0) }
                    ))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Music Volume")
                        Slider(
                            value: Binding(
                                get: { viewModel.settings.musicVolume },
                                set: { viewModel.setMusicVolume($0) }
                            ),
                            in: 0...1
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("SFX Volume")
                        Slider(
                            value: Binding(
                                get: { viewModel.settings.sfxVolume },
                                set: { viewModel.setSFXVolume($0) }
                            ),
                            in: 0...1
                        )
                    }
                }

                Section("Controls") {
                    Toggle("Haptics", isOn: Binding(
                        get: { viewModel.settings.hapticsEnabled },
                        set: { viewModel.setHapticsEnabled($0) }
                    ))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text Scale")
                        Slider(
                            value: Binding(
                                get: { viewModel.settings.textScale },
                                set: { viewModel.setTextScale($0) }
                            ),
                            in: 0.8...1.3
                        )
                    }
                }

                Section("Tutorial") {
                    Button("Replay Tutorial") {
                        viewModel.replayTutorial()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.14, blue: 0.24), Color(red: 0.02, green: 0.20, blue: 0.17)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        viewModel.closeSettings()
                    }
                }
            }
        }
    }
}
