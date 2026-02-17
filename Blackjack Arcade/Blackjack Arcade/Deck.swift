import Foundation

class Deck {
    private var cards: [Card] = []

    init() {
        self.reset()
    }

    func reset() {
        self.cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                self.cards.append(Card(suit: suit, rank: rank))
            }
        }
        self.shuffle()
    }

    func shuffle() {
        self.cards.shuffle()
    }

    func deal() -> Card? {
        if self.cards.isEmpty {
            return nil
        }
        return self.cards.removeLast()
    }

    var remainingCards: Int {
        return self.cards.count
    }
}
