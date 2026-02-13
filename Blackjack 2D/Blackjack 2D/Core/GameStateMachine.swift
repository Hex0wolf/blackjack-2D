import Foundation

struct GameStateMachine {
    private(set) var phase: GamePhase = .idle

    private static let allowedTransitions: [GamePhase: Set<GamePhase>] = [
        .idle: [.betting],
        .betting: [.initialDeal],
        .initialDeal: [.playerTurn, .dealerTurn, .settle],
        .playerTurn: [.dealerTurn, .settle],
        .dealerTurn: [.settle],
        .settle: [.rewards],
        .rewards: [.nextRound],
        .nextRound: [.betting]
    ]

    mutating func reset(to phase: GamePhase = .idle) {
        self.phase = phase
    }

    func canTransition(to newPhase: GamePhase) -> Bool {
        nextPhases.contains(newPhase)
    }

    var nextPhases: Set<GamePhase> {
        Self.allowedTransitions[phase, default: []]
    }

    @discardableResult
    mutating func transition(to newPhase: GamePhase) -> Bool {
        guard canTransition(to: newPhase) else {
            return false
        }
        phase = newPhase
        return true
    }
}
