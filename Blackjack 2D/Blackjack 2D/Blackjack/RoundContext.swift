import Foundation

struct RoundContext: Codable {
    var phase: GamePhase
    var bet: Int
    var shoe: [Card]
    var dealerHand: Hand
    var playerHand: Hand
    var splitHand: Hand?
    var activeHand: PlayerHandSlot
    var dealerHoleCardHidden: Bool
    var allowedActions: Set<PlayerAction>
    var bankroll: Int
    var primaryBet: Int
    var splitBet: Int?
    var primaryHasStood: Bool
    var splitHasStood: Bool
    var primaryDoubled: Bool
    var splitDoubled: Bool
    var events: [RoundEvent]

    static func bettingContext(shoe: [Card], bankroll: Int, bet: Int) -> RoundContext {
        RoundContext(
            phase: .betting,
            bet: bet,
            shoe: shoe,
            dealerHand: Hand(),
            playerHand: Hand(),
            splitHand: nil,
            activeHand: .primary,
            dealerHoleCardHidden: true,
            allowedActions: [],
            bankroll: bankroll,
            primaryBet: bet,
            splitBet: nil,
            primaryHasStood: false,
            splitHasStood: false,
            primaryDoubled: false,
            splitDoubled: false,
            events: []
        )
    }

    var hasSplit: Bool {
        splitHand != nil
    }

    func hand(for slot: PlayerHandSlot) -> Hand {
        switch slot {
        case .primary:
            return playerHand
        case .split:
            return splitHand ?? Hand()
        }
    }

    mutating func set(hand: Hand, for slot: PlayerHandSlot) {
        switch slot {
        case .primary:
            playerHand = hand
        case .split:
            splitHand = hand
        }
    }

    func bet(for slot: PlayerHandSlot) -> Int {
        switch slot {
        case .primary:
            return primaryBet
        case .split:
            return splitBet ?? 0
        }
    }

    mutating func setBet(_ amount: Int, for slot: PlayerHandSlot) {
        switch slot {
        case .primary:
            primaryBet = amount
        case .split:
            splitBet = amount
        }
    }

    func hasStood(for slot: PlayerHandSlot) -> Bool {
        switch slot {
        case .primary:
            return primaryHasStood
        case .split:
            return splitHasStood
        }
    }

    mutating func setHasStood(_ stood: Bool, for slot: PlayerHandSlot) {
        switch slot {
        case .primary:
            primaryHasStood = stood
        case .split:
            splitHasStood = stood
        }
    }

    func isDoubled(for slot: PlayerHandSlot) -> Bool {
        switch slot {
        case .primary:
            return primaryDoubled
        case .split:
            return splitDoubled
        }
    }

    mutating func setIsDoubled(_ doubled: Bool, for slot: PlayerHandSlot) {
        switch slot {
        case .primary:
            primaryDoubled = doubled
        case .split:
            splitDoubled = doubled
        }
    }

    mutating func drawCard() -> Card? {
        shoe.popLast()
    }

    var committedBet: Int {
        primaryBet + (splitBet ?? 0)
    }
}
