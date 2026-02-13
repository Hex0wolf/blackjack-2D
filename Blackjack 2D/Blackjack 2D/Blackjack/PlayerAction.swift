import Foundation

enum PlayerAction: String, Codable, CaseIterable, Hashable {
    case hit
    case stand
    case double
    case split

    var label: String {
        rawValue.capitalized
    }
}
