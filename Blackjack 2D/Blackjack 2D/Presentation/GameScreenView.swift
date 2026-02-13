import SwiftUI

struct GameScreenView: View {
    @ObservedObject var viewModel: BlackjackViewModel
    @State private var isDrawerExpanded = false

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.12, blue: 0.08), Color(red: 0.04, green: 0.05, blue: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isLandscape {
                    HStack(spacing: 12) {
                        GameSceneView(viewModel: viewModel)

                        hudPanel
                            .frame(width: min(340, geometry.size.width * 0.35))
                    }
                    .padding(12)
                } else {
                    VStack(spacing: 12) {
                        GameSceneView(viewModel: viewModel)
                            .frame(height: geometry.size.height * 0.52)

                        hudPanel
                    }
                    .padding(12)
                }

                if viewModel.tutorialVisible {
                    TutorialOverlayView(viewModel: viewModel)
                        .padding(18)
                }
            }
        }
    }

    private var hudPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            primaryHeader
            phaseStatusPanel
            controlsPanel

            Button(isDrawerExpanded ? "Hide Run Details" : "Show Run Details") {
                withAnimation(.easeOut(duration: 0.18)) {
                    isDrawerExpanded.toggle()
                }
            }
            .buttonStyle(HUDButtonStyle(color: Color(red: 0.24, green: 0.30, blue: 0.50)))

            if isDrawerExpanded {
                ScrollView {
                    drawerPanel
                }
                .frame(maxHeight: 240)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        )
    }

    private var primaryHeader: some View {
        HStack(spacing: 10) {
            Button("Menu") {
                viewModel.openMenu()
            }
            .buttonStyle(HUDButtonStyle(color: Color(red: 0.22, green: 0.36, blue: 0.66)))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Chips: \(viewModel.profile.chips)")
                Text("Bet: \(viewModel.adjustedBetPreview)")
            }
            .font(.system(size: 14 * viewModel.settings.textScale, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
        }
    }

    private var phaseStatusPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.phase.rawValue.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white.opacity(0.86))
            Text(viewModel.snapshot.status)
                .font(.system(size: 16 * viewModel.settings.textScale, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var drawerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            statsPanel
            modifierPanel

            if let roundResult = viewModel.roundResult {
                resultPanel(result: roundResult)
            }

            if viewModel.canClaimDailyGrant {
                Button("Claim Daily +\(PlayerProfile.dailyGrantAmount)") {
                    viewModel.claimDailyGrant()
                }
                .buttonStyle(HUDButtonStyle(color: Color(red: 0.20, green: 0.62, blue: 0.38)))
            }
        }
    }

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Run Details")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)

            Text("Level: \(viewModel.profile.level)  XP: \(viewModel.profile.xp)")
                .foregroundStyle(.white)
            Text("Streak: \(viewModel.profile.winStreak)  Best: \(viewModel.profile.statistics.bestStreak)")
                .foregroundStyle(.white)
        }
        .font(.system(size: 15 * viewModel.settings.textScale, weight: .semibold, design: .rounded))
    }

    private var modifierPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modifier")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)

            Picker("Modifier", selection: modifierBinding) {
                ForEach(viewModel.availableModifiers) { modifier in
                    Text(modifier.displayName).tag(modifier.id)
                }
            }
            .pickerStyle(.menu)
            .disabled(viewModel.phase != .betting)
            .tint(.white)

            if let selected = viewModel.availableModifiers.first(where: { $0.id == viewModel.selectedModifier.id }) {
                Text(selected.description)
                    .font(.system(size: 13 * viewModel.settings.textScale, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legal Actions")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)

            if viewModel.phase == .betting {
                HStack(spacing: 10) {
                    Button("-10") { viewModel.changeBet(by: -10) }
                        .buttonStyle(HUDButtonStyle(color: Color(red: 0.40, green: 0.24, blue: 0.24)))

                    Button("+10") { viewModel.changeBet(by: 10) }
                        .buttonStyle(HUDButtonStyle(color: Color(red: 0.20, green: 0.34, blue: 0.22)))

                    Text("Base: \(viewModel.baseBet)")
                        .font(.system(size: 13 * viewModel.settings.textScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                }

                Button("Place Bet") {
                    viewModel.beginRound()
                }
                .buttonStyle(HUDButtonStyle(color: Color(red: 0.14, green: 0.70, blue: 0.46)))
                .disabled(!viewModel.canStartRound)

            } else if viewModel.phase == .playerTurn {
                if viewModel.allowedActions.isEmpty {
                    Text("No legal actions available")
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 8)], spacing: 8) {
                        ForEach(viewModel.allowedActions, id: \.self) { action in
                            Button(action.label) {
                                viewModel.perform(action)
                            }
                            .buttonStyle(HUDButtonStyle(color: colorFor(action: action)))
                            .disabled(viewModel.isInputLocked)
                        }
                    }
                }
            } else {
                Text("Round is resolving...")
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func resultPanel(result: RoundResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Latest Outcome")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
            Text("Outcome: \(result.outcome.rawValue.capitalized)")
                .foregroundStyle(.white)
            Text("Net: \(result.netPayout)")
                .foregroundStyle(result.netPayout >= 0 ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
        }
        .font(.system(size: 14 * viewModel.settings.textScale, weight: .bold, design: .rounded))
    }

    private var modifierBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedModifier.id },
            set: { newID in
                if let modifier = viewModel.availableModifiers.first(where: { $0.id == newID }) {
                    viewModel.selectModifier(modifier)
                }
            }
        )
    }

    private func colorFor(action: PlayerAction) -> Color {
        switch action {
        case .hit:
            return Color(red: 0.14, green: 0.57, blue: 0.40)
        case .stand:
            return Color(red: 0.26, green: 0.42, blue: 0.72)
        case .double:
            return Color(red: 0.72, green: 0.46, blue: 0.20)
        case .split:
            return Color(red: 0.64, green: 0.28, blue: 0.42)
        }
    }
}

private struct HUDButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.70 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TutorialOverlayView: View {
    @ObservedObject var viewModel: BlackjackViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Tutorial")
                    .font(.system(size: 24, weight: .black, design: .rounded))

                Text("Step \(viewModel.tutorialStepIndex + 1) of \(viewModel.tutorialSteps.count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))

                Text(viewModel.tutorialSteps[viewModel.tutorialStepIndex])
                    .font(.system(size: 18 * viewModel.settings.textScale, weight: .semibold, design: .rounded))

                HStack {
                    Button("Skip") {
                        viewModel.skipTutorial()
                    }
                    .buttonStyle(HUDButtonStyle(color: Color(red: 0.44, green: 0.24, blue: 0.24)))

                    Spacer()

                    Button(viewModel.tutorialStepIndex == viewModel.tutorialSteps.count - 1 ? "Finish" : "Next") {
                        viewModel.nextTutorialStep()
                    }
                    .buttonStyle(HUDButtonStyle(color: Color(red: 0.15, green: 0.62, blue: 0.40)))
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
            .padding(24)
        }
    }
}
