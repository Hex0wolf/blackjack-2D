import Foundation

enum RoundOutcome: String, Codable {
    case playerWin
    case dealerWin
    case push
    case blackjack
    case bust
}

enum PlayerHandSlot: String, Codable, CaseIterable {
    case primary
    case split
}

struct HandResolution: Codable {
    let hand: PlayerHandSlot
    let outcome: RoundOutcome
    let payout: Int
}

struct RoundResult: Codable {
    let netPayout: Int
    let outcome: RoundOutcome
    let handResolutions: [HandResolution]
    let eventList: [RoundEvent]
}
