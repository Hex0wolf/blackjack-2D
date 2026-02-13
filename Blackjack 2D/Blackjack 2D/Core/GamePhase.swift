import Foundation

enum GamePhase: String, Codable, CaseIterable {
    case idle
    case betting
    case initialDeal
    case playerTurn
    case dealerTurn
    case settle
    case rewards
    case nextRound
}
