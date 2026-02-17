import Foundation

class Hand {
    var cards: [Card] = []

    var score: Int {
        var total = 0
        var aceCount = 0

        for card in cards {
            let value = card.rank.value
            total += value
            if card.rank == .ace {
                aceCount += 1
            }
        }

        // Adjust for Aces if bust
        while total > 21 && aceCount > 0 {
            total -= 10
            aceCount -= 1
        }

        return total
    }

    var isBlackjack: Bool {
        return cards.count == 2 && score == 21
    }

    var isBusted: Bool {
        return score > 21
    }

    func add(_ card: Card) {
        cards.append(card)
    }

    func reset() {
        cards.removeAll()
    }

    var description: String {
        return cards.map { $0.description }.joined(separator: ", ")
    }
}
