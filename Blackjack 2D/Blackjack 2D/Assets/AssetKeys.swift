import Foundation

enum SFXKey: String, Codable, CaseIterable {
    case deal
    case chipBet
    case tapConfirm
    case roundWin
    case roundLose
    case blackjack
    case levelUp
}

enum MusicTrack: String, Codable, CaseIterable {
    case menuLoop
    case roundLoop
    case tensionLoop
}

enum SpriteKey {
    static let tableBackground = "table_bg"
    static let cardBack = "card_back"
    static let chip = "chip"
}
