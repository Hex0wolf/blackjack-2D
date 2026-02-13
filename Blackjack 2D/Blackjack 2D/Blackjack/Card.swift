import Foundation

enum Suit: String, Codable, CaseIterable {
    case hearts
    case diamonds
    case clubs
    case spades

    var symbol: String {
        switch self {
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        case .spades: return "♠"
        }
    }
}

enum Rank: Int, Codable, CaseIterable {
    case ace = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13

    var blackjackValue: Int {
        min(rawValue, 10)
    }

    var shortName: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }
}

struct Card: Codable, Hashable {
    let suit: Suit
    let rank: Rank

    var displayName: String {
        "\(rank.shortName)\(suit.symbol)"
    }
}
