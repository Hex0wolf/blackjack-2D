import Foundation

enum DeckFactory {
    static func makeShuffledShoe(deckCount: Int = 4, seed: UInt64? = nil) -> [Card] {
        let decks = max(1, deckCount)
        var cards: [Card] = []
        cards.reserveCapacity(decks * 52)

        for _ in 0..<decks {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    cards.append(Card(suit: suit, rank: rank))
                }
            }
        }

        var generator = SeededRandom(seed: seed ?? UInt64(Date().timeIntervalSinceReferenceDate * 1_000_000))
        cards.shuffle(using: &generator)
        return cards
    }
}
