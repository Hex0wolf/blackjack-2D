import Foundation

struct Hand: Codable, Hashable {
    var cards: [Card] = []

    var hardValue: Int {
        cards.reduce(0) { $0 + ($1.rank == .ace ? 1 : $1.rank.blackjackValue) }
    }

    var bestValue: Int {
        let aceCount = cards.filter { $0.rank == .ace }.count
        var best = hardValue
        guard aceCount > 0 else { return best }

        for _ in 0..<aceCount {
            let candidate = best + 10
            if candidate <= 21 {
                best = candidate
            }
        }
        return best
    }

    var isSoft: Bool {
        cards.contains(where: { $0.rank == .ace }) && bestValue != hardValue
    }

    var isBlackjack: Bool {
        cards.count == 2 && bestValue == 21
    }

    var isBust: Bool {
        bestValue > 21
    }

    mutating func addCard(_ card: Card) {
        cards.append(card)
    }

    func rendered(hidingSecondCard: Bool = false) -> String {
        guard !cards.isEmpty else { return "--" }
        if hidingSecondCard, cards.count > 1 {
            let visible = cards.enumerated().map { index, card in
                index == 1 ? "??" : card.displayName
            }
            return visible.joined(separator: " ")
        }
        return cards.map(\.displayName).joined(separator: " ")
    }
}
