import Foundation

struct GameSnapshot: Equatable {
    let phase: GamePhase
    let dealerCards: String
    let dealerValue: String
    let playerCards: String
    let playerValue: String
    let splitCards: String?
    let splitValue: String?
    let activeHand: PlayerHandSlot
    let status: String
    let recentEvents: [RoundEvent]

    static let empty = GameSnapshot(
        phase: .idle,
        dealerCards: "--",
        dealerValue: "",
        playerCards: "--",
        playerValue: "",
        splitCards: nil,
        splitValue: nil,
        activeHand: .primary,
        status: "Ready",
        recentEvents: []
    )
}
