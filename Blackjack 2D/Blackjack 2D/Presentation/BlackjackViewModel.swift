import Foundation
import Combine
import SwiftUI

@MainActor
final class BlackjackViewModel: ObservableObject {
    @Published private(set) var profile: PlayerProfile
    @Published private(set) var settings: GameSettings
    @Published private(set) var phase: GamePhase = .idle
    @Published private(set) var roundContext: RoundContext
    @Published private(set) var roundResult: RoundResult?
    @Published private(set) var snapshot: GameSnapshot = .empty
    @Published private(set) var statusMessage: String = "Welcome to Pixel Blackjack"
    @Published private(set) var isInputLocked: Bool = false

    @Published var baseBet: Int
    @Published var selectedModifier: RunModifier
    @Published var tutorialStepIndex: Int = 0
    @Published var activeScreen: RootScreen = .menu

    private var stateMachine = GameStateMachine()

    private let rulesEngine: StandardBlackjackRulesEngine
    private let progressionService: DefaultProgressionService
    private let saveRepository: SaveRepository
    private let audioService: AudioService
    private let hapticService: HapticService
    private let shoeProvider: any ShoeProviding

    private static let minimumBet = 10
    private static let maximumBet = 1_000

    let tutorialSteps: [String] = [
        "Place a bet to start each round.",
        "Use only legal actions: hit, stand, double, split.",
        "Build streaks for bonus XP and unlocks.",
        "If you run out of chips, claim daily free chips."
    ]

    convenience init() {
        self.init(
            rulesEngine: StandardBlackjackRulesEngine(),
            progressionService: DefaultProgressionService(),
            saveRepository: JSONSaveRepository(),
            audioService: DefaultAudioService(),
            hapticService: DefaultHapticService()
        )
    }

    init(
        rulesEngine: StandardBlackjackRulesEngine,
        progressionService: DefaultProgressionService,
        saveRepository: SaveRepository,
        audioService: AudioService,
        hapticService: HapticService,
        shoeProvider: (any ShoeProviding)? = nil
    ) {
        self.rulesEngine = rulesEngine
        self.progressionService = progressionService
        self.saveRepository = saveRepository
        self.audioService = audioService
        self.hapticService = hapticService
        self.shoeProvider = shoeProvider ?? RandomShoeProvider()

        let loadedSettings = saveRepository.loadSettings()
        var loadedProfile = saveRepository.loadProfile()
        loadedProfile.settings = loadedSettings

        profile = loadedProfile
        settings = loadedSettings

        let initialBet = max(Self.minimumBet, min(50, loadedProfile.chips))
        baseBet = initialBet
        selectedModifier = .none

        let initialShoe = self.shoeProvider.makeShoe()
        roundContext = RoundContext.bettingContext(
            shoe: initialShoe,
            bankroll: loadedProfile.chips,
            bet: initialBet
        )

        stateMachine.reset(to: .idle)
        refreshSnapshot(with: [])
        applyAudioMix()
        audioService.playMusic(.menuLoop)
    }

    var allowedActions: [PlayerAction] {
        PlayerAction.allCases.filter { roundContext.allowedActions.contains($0) }
    }

    var adjustedBetPreview: Int {
        selectedModifier.adjustedBet(baseBet)
    }

    var availableModifiers: [RunModifier] {
        guard profile.unlockFlags.contains("modifier.slot.1") else {
            return [.none]
        }
        return RunModifier.all
    }

    var canStartRound: Bool {
        phase == .betting && profile.chips >= adjustedBetPreview
    }

    var canClaimDailyGrant: Bool {
        isDailyGrantEligible && profile.chips < Self.minimumBet
    }

    var tutorialVisible: Bool {
        activeScreen == .game && !settings.tutorialCompleted
    }

    var currentHandDescriptor: String {
        if roundContext.activeHand == .split {
            return "Split Hand"
        }
        return "Main Hand"
    }

    func startGame() {
        activeScreen = .game
        roundResult = nil
        statusMessage = "Place your bet."

        if stateMachine.phase == .idle {
            transitionTo(.betting)
        } else {
            stateMachine.reset(to: .betting)
            phase = .betting
        }

        roundContext = RoundContext.bettingContext(
            shoe: refreshedShoeIfNeeded(roundContext.shoe),
            bankroll: profile.chips,
            bet: adjustedBetPreview
        )
        refreshSnapshot(with: [])
        audioService.playMusic(.roundLoop)
    }

    func openMenu() {
        activeScreen = .menu
        stateMachine.reset(to: .idle)
        phase = .idle
        roundContext.phase = .idle
        refreshSnapshot(with: [])
        audioService.playMusic(.menuLoop)
    }

    func openSettings() {
        activeScreen = .settings
    }

    func closeSettings() {
        activeScreen = .menu
    }

    func changeBet(by delta: Int) {
        guard phase == .betting else { return }

        let maxBet = max(Self.minimumBet, min(Self.maximumBet, profile.chips))
        baseBet = min(max(baseBet + delta, Self.minimumBet), maxBet)
        roundContext.bet = adjustedBetPreview
        roundContext.primaryBet = adjustedBetPreview
        refreshSnapshot(with: [])
    }

    func selectModifier(_ modifier: RunModifier) {
        guard availableModifiers.contains(modifier) else {
            selectedModifier = .none
            return
        }

        selectedModifier = modifier
        roundContext.bet = adjustedBetPreview
        roundContext.primaryBet = adjustedBetPreview
        refreshSnapshot(with: [])
    }

    func beginRound() {
        guard phase == .betting else { return }

        let wager = adjustedBetPreview
        guard profile.chips >= wager else {
            statusMessage = canClaimDailyGrant ? "Claim your daily chips first." : "Not enough chips for this bet."
            refreshSnapshot(with: [])
            return
        }

        profile.chips -= wager
        persistProfileAndSettings()

        let newContext = RoundContext.bettingContext(
            shoe: refreshedShoeIfNeeded(roundContext.shoe),
            bankroll: profile.chips,
            bet: wager
        )

        guard transitionTo(.initialDeal) else { return }

        roundResult = nil
        roundContext = rulesEngine.dealInitialCards(context: newContext)
        profile.chips = roundContext.bankroll

        if roundContext.phase == .playerTurn {
            guard transitionTo(.playerTurn) else { return }
        } else if roundContext.phase == .dealerTurn {
            guard transitionTo(.dealerTurn) else { return }
        }

        applyRoundEvents(roundContext.events)
        refreshSnapshot(with: roundContext.events)

        if phase == .dealerTurn {
            resolveDealerAndSettleRound()
        }
    }

    func perform(_ action: PlayerAction) {
        guard phase == .playerTurn, !isInputLocked else { return }
        guard roundContext.allowedActions.contains(action) else { return }

        hapticService.tap(enabled: settings.hapticsEnabled)
        audioService.playSFX(.tapConfirm)

        roundContext = rulesEngine.apply(action: action, context: roundContext)

        if roundContext.phase == .dealerTurn {
            guard transitionTo(.dealerTurn) else { return }
            applyRoundEvents(roundContext.events)
            refreshSnapshot(with: roundContext.events)
            resolveDealerAndSettleRound()
            return
        }

        roundContext.phase = .playerTurn
        roundContext.allowedActions = rulesEngine.allowedActions(context: roundContext)
        phase = .playerTurn

        applyRoundEvents(roundContext.events)
        refreshSnapshot(with: roundContext.events)
    }

    func claimDailyGrant() {
        guard profile.grantDailyChipsIfEligible() else {
            statusMessage = "Daily grant already claimed today."
            refreshSnapshot(with: [])
            return
        }

        statusMessage = "Daily grant claimed: +\(PlayerProfile.dailyGrantAmount) chips."
        persistProfileAndSettings()

        if phase == .betting {
            roundContext.bankroll = profile.chips
        }

        hapticService.notify(event: .unlock, enabled: settings.hapticsEnabled)
        refreshSnapshot(with: [.unlock])
    }

    func nextTutorialStep() {
        guard tutorialVisible else { return }

        if tutorialStepIndex < tutorialSteps.count - 1 {
            tutorialStepIndex += 1
        } else {
            completeTutorial()
        }
    }

    func skipTutorial() {
        completeTutorial()
    }

    func replayTutorial() {
        tutorialStepIndex = 0
        settings.tutorialCompleted = false
        persistProfileAndSettings()
    }

    func setMusicEnabled(_ value: Bool) {
        settings.musicEnabled = value
        persistProfileAndSettings()
        applyAudioMix()
    }

    func setSFXEnabled(_ value: Bool) {
        settings.sfxEnabled = value
        persistProfileAndSettings()
        applyAudioMix()
    }

    func setHapticsEnabled(_ value: Bool) {
        settings.hapticsEnabled = value
        persistProfileAndSettings()
    }

    func setMusicVolume(_ value: Double) {
        settings.musicVolume = value
        persistProfileAndSettings()
        applyAudioMix()
    }

    func setSFXVolume(_ value: Double) {
        settings.sfxVolume = value
        persistProfileAndSettings()
        applyAudioMix()
    }

    func setTextScale(_ value: Double) {
        settings.textScale = value
        persistProfileAndSettings()
    }

    private func resolveDealerAndSettleRound() {
        isInputLocked = true

        roundContext = rulesEngine.playDealerTurn(context: roundContext)
        let dealerEvents = roundContext.events
        applyRoundEvents(dealerEvents)

        guard transitionTo(.settle) else {
            isInputLocked = false
            return
        }
        roundContext.phase = .settle

        let result = rulesEngine.resolveRound(context: roundContext)
        roundResult = result

        let totalCredit = roundContext.committedBet + result.netPayout
        profile.chips += totalCredit

        let progression = progressionService.applyRound(
            result: result,
            profile: profile,
            modifier: selectedModifier.id == RunModifier.none.id ? nil : selectedModifier
        )
        profile = progression.profile

        let settleEvents = result.eventList + progression.events
        applyRoundEvents(settleEvents)

        guard transitionTo(.rewards) else {
            isInputLocked = false
            return
        }
        roundContext.phase = .rewards

        guard transitionTo(.nextRound) else {
            isInputLocked = false
            return
        }
        roundContext.phase = .nextRound

        guard transitionTo(.betting) else {
            isInputLocked = false
            return
        }

        roundContext = RoundContext.bettingContext(
            shoe: refreshedShoeIfNeeded(roundContext.shoe),
            bankroll: profile.chips,
            bet: adjustedBetPreview
        )

        roundContext.allowedActions = []
        roundContext.events = []

        statusMessage = messageFor(result: result)
        persistProfileAndSettings()
        refreshSnapshot(with: dealerEvents + settleEvents)

        isInputLocked = false
    }

    private func completeTutorial() {
        tutorialStepIndex = 0
        settings.tutorialCompleted = true
        persistProfileAndSettings()
    }

    private func refreshedShoeIfNeeded(_ current: [Card]) -> [Card] {
        if current.count < 40 {
            return shoeProvider.makeShoe()
        }
        return current
    }

    @discardableResult
    private func transitionTo(_ newPhase: GamePhase) -> Bool {
        guard stateMachine.transition(to: newPhase) else {
            assertionFailure("Invalid phase transition from \(stateMachine.phase.rawValue) to \(newPhase.rawValue)")
            return false
        }

        phase = newPhase
        return true
    }

    private func applyRoundEvents(_ events: [RoundEvent]) {
        for event in events {
            switch event {
            case .cardDealt:
                audioService.playSFX(.deal)
            case .chipBet:
                audioService.playSFX(.chipBet)
            case .playerWin:
                audioService.playSFX(.roundWin)
            case .dealerWin, .bust:
                audioService.playSFX(.roundLose)
            case .blackjack:
                audioService.playSFX(.blackjack)
                audioService.duckMusic(for: 0.4)
            case .levelUp:
                audioService.playSFX(.levelUp)
            case .unlock, .winBig, .push, .roundStart:
                break
            }

            hapticService.notify(event: event, enabled: settings.hapticsEnabled)
        }
    }

    private func applyAudioMix() {
        audioService.setMix(settings: settings)
    }

    private func persistProfileAndSettings() {
        profile.settings = settings
        saveRepository.saveProfile(profile)
        saveRepository.saveSettings(settings)
    }

    private func refreshSnapshot(with events: [RoundEvent]) {
        let dealerCards = roundContext.dealerHand.rendered(hidingSecondCard: roundContext.dealerHoleCardHidden)
        let dealerValue: String
        if roundContext.dealerHand.cards.isEmpty {
            dealerValue = "--"
        } else if roundContext.dealerHoleCardHidden,
           roundContext.dealerHand.cards.count > 1 {
            dealerValue = "?"
        } else {
            dealerValue = "\(roundContext.dealerHand.bestValue)"
        }

        let split = roundContext.splitHand
        let status = statusForCurrentState()

        snapshot = GameSnapshot(
            phase: phase,
            dealerCards: dealerCards,
            dealerValue: dealerValue,
            playerCards: roundContext.playerHand.rendered(),
            playerValue: "\(roundContext.playerHand.bestValue)",
            splitCards: split?.rendered(),
            splitValue: split.map { "\($0.bestValue)" },
            activeHand: roundContext.activeHand,
            status: status,
            recentEvents: Array(events.suffix(3))
        )
    }

    private func statusForCurrentState() -> String {
        switch phase {
        case .idle:
            return "Select Play from the menu"
        case .betting:
            return statusMessage == "Welcome to Pixel Blackjack" ? "Place your bet" : statusMessage
        case .initialDeal:
            return "Dealing cards..."
        case .playerTurn:
            return "\(currentHandDescriptor): choose your action"
        case .dealerTurn:
            return "Dealer turn"
        case .settle:
            return "Settling round..."
        case .rewards:
            return "Applying rewards"
        case .nextRound:
            return "Preparing next round"
        }
    }

    private func messageFor(result: RoundResult) -> String {
        switch result.outcome {
        case .blackjack:
            return "Blackjack! Net +\(result.netPayout)"
        case .playerWin:
            return "You win! Net +\(result.netPayout)"
        case .dealerWin:
            return "Dealer wins. Net \(result.netPayout)"
        case .push:
            return "Push. Bet returned."
        case .bust:
            return "Bust. Better luck next hand."
        }
    }

    private var isDailyGrantEligible: Bool {
        guard let last = profile.lastDailyGrantAt else {
            return true
        }
        return Date().timeIntervalSince(last) >= PlayerProfile.dailyGrantCooldown
    }
}

enum RootScreen: Equatable {
    case menu
    case game
    case settings
}
