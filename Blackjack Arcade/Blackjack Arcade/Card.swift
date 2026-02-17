import Foundation

enum Suit: String, CaseIterable {
    case clubs = "Clubs"
    case diamonds = "Diamonds"
    case hearts = "Hearts"
    case spades = "Spades"

    var symbol: String {
        switch self {
        case .clubs: return "♣️"
        case .diamonds: return "♦️"
        case .hearts: return "♥️"
        case .spades: return "♠️"
        }
    }
}

enum Rank: Int, CaseIterable {
    case ace = 1
    case two, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king

    var description: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return String(self.rawValue)
        }
    }

    var value: Int {
        switch self {
        case .ace: return 11 // Default to 11, logic handles bust separately
        case .jack, .queen, .king: return 10
        default: return self.rawValue
        }
    }
}

struct Card: CustomStringConvertible, Equatable {
    let suit: Suit
    let rank: Rank

    var description: String {
        return "\(rank.description)\(suit.symbol)"
    }

    // For asset naming later
    var imageName: String {
        return "\(rank.description)_\(suit.rawValue)"
    }
}
