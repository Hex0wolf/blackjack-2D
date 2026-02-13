import Foundation

struct RunModifier: Codable, Hashable, Identifiable {
    let id: String
    let displayName: String
    let description: String
    let betMultiplier: Double
    let xpMultiplier: Double
    let streakBonus: Int
    let dealerVarianceBias: Int

    func adjustedBet(_ bet: Int) -> Int {
        max(10, Int((Double(bet) * betMultiplier).rounded()))
    }

    static let none = RunModifier(
        id: "none",
        displayName: "Classic Table",
        description: "No active modifier.",
        betMultiplier: 1.0,
        xpMultiplier: 1.0,
        streakBonus: 0,
        dealerVarianceBias: 0
    )

    static let all: [RunModifier] = [
        .none,
        RunModifier(
            id: "lucky-seat",
            displayName: "Lucky Seat",
            description: "Small XP bonus every round.",
            betMultiplier: 1.0,
            xpMultiplier: 1.2,
            streakBonus: 1,
            dealerVarianceBias: 0
        ),
        RunModifier(
            id: "high-roller",
            displayName: "High Roller",
            description: "Higher bet scaling and bigger streak rewards.",
            betMultiplier: 1.25,
            xpMultiplier: 1.1,
            streakBonus: 2,
            dealerVarianceBias: 0
        )
    ]
}
