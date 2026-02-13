import Foundation

struct PlayerStatistics: Codable {
    var roundsPlayed: Int = 0
    var roundsWon: Int = 0
    var roundsLost: Int = 0
    var roundsPushed: Int = 0
    var blackjacks: Int = 0
    var bestStreak: Int = 0
}

struct PlayerProfile: Codable {
    var chips: Int
    var xp: Int
    var level: Int
    var unlockFlags: Set<String>
    var settings: GameSettings
    var statistics: PlayerStatistics
    var winStreak: Int
    var lastDailyGrantAt: Date?

    static let startingChips = 1_000
    static let dailyGrantAmount = 500
    static let dailyGrantCooldown: TimeInterval = 24 * 60 * 60

    static var `default`: PlayerProfile {
        PlayerProfile(
            chips: startingChips,
            xp: 0,
            level: 1,
            unlockFlags: [],
            settings: GameSettings(),
            statistics: PlayerStatistics(),
            winStreak: 0,
            lastDailyGrantAt: nil
        )
    }

    mutating func grantDailyChipsIfEligible(now: Date = Date()) -> Bool {
        if let lastDailyGrantAt,
           now.timeIntervalSince(lastDailyGrantAt) < Self.dailyGrantCooldown {
            return false
        }

        chips += Self.dailyGrantAmount
        lastDailyGrantAt = now
        return true
    }
}
