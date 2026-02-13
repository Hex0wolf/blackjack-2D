import Foundation
@testable import Blackjack_2D

enum TestFixtures {
    static func card(_ rank: Rank, _ suit: Suit = .spades) -> Card {
        Card(suit: suit, rank: rank)
    }

    static func shoe(drawOrder: [Card]) -> [Card] {
        // RoundContext draws from the end of the array.
        drawOrder.reversed()
    }

    static func playerTurnContext(
        bankroll: Int = 1_000,
        bet: Int = 100,
        playerCards: [Card],
        dealerCards: [Card] = [],
        drawOrder: [Card] = []
    ) -> RoundContext {
        var context = RoundContext.bettingContext(
            shoe: shoe(drawOrder: drawOrder),
            bankroll: bankroll,
            bet: bet
        )
        context.phase = .playerTurn
        context.playerHand = Hand(cards: playerCards)
        context.dealerHand = Hand(cards: dealerCards)
        context.primaryBet = bet
        context.bet = bet
        context.dealerHoleCardHidden = false
        return context
    }
}
