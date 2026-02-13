import Foundation

struct GameStateMachine {
    private(set) var phase: GamePhase = .idle

    mutating func reset(to phase: GamePhase = .idle) {
        self.phase = phase
    }

    @discardableResult
    mutating func transition(to newPhase: GamePhase) -> Bool {
        guard allowedTransitions[phase, default: []].contains(newPhase) else {
            return false
        }
        phase = newPhase
        return true
    }

    private var allowedTransitions: [GamePhase: Set<GamePhase>] {
        [
            .idle: [.betting],
            .betting: [.initialDeal],
            .initialDeal: [.playerTurn, .dealerTurn, .settle],
            .playerTurn: [.dealerTurn, .settle],
            .dealerTurn: [.settle],
            .settle: [.rewards],
            .rewards: [.nextRound],
            .nextRound: [.betting]
        ]
    }
}
