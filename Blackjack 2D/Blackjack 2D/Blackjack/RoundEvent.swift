import Foundation

enum RoundEvent: String, Codable, CaseIterable, Hashable {
    case roundStart
    case chipBet
    case cardDealt
    case blackjack
    case bust
    case playerWin
    case dealerWin
    case push
    case winBig
    case levelUp
    case unlock
}
