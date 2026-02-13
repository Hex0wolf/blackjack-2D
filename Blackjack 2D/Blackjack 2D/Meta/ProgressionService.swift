import Foundation

protocol ProgressionService {
    func xpGain(for result: RoundResult, streak: Int, modifier: RunModifier?) -> Int
    func levelThreshold(for level: Int) -> Int
    func resolveUnlocks(for level: Int, existingUnlocks: Set<String>) -> Set<String>
}

struct ProgressionDelta {
    let profile: PlayerProfile
    let events: [RoundEvent]
    let unlocked: Set<String>
}

struct DefaultProgressionService: ProgressionService {
    func xpGain(for result: RoundResult, streak: Int, modifier: RunModifier?) -> Int {
        var base = 30
        switch result.outcome {
        case .blackjack:
            base += 45
        case .playerWin:
            base += 25
        case .push:
            base += 10
        case .dealerWin, .bust:
            base += 5
        }

        if streak > 1 {
            base += min(50, streak * 5)
        }

        if result.netPayout > 0 {
            base += min(30, result.netPayout / 20)
        }

        if let modifier {
            base += modifier.streakBonus
            base = Int((Double(base) * modifier.xpMultiplier).rounded())
        }

        return max(10, base)
    }

    func levelThreshold(for level: Int) -> Int {
        max(100, level * level * 120)
    }

    func resolveUnlocks(for level: Int, existingUnlocks: Set<String>) -> Set<String> {
        var unlocks = existingUnlocks
        if level >= 2 { unlocks.insert("table.skin.neon") }
        if level >= 3 { unlocks.insert("cards.back.spark") }
        if level >= 4 { unlocks.insert("modifier.slot.1") }
        return unlocks
    }

    func applyRound(result: RoundResult, profile: PlayerProfile, modifier: RunModifier?) -> ProgressionDelta {
        var updated = profile
        var events: [RoundEvent] = []

        updated.statistics.roundsPlayed += 1

        switch result.outcome {
        case .playerWin, .blackjack:
            updated.statistics.roundsWon += 1
            updated.winStreak += 1
        case .push:
            updated.statistics.roundsPushed += 1
        case .dealerWin, .bust:
            updated.statistics.roundsLost += 1
            updated.winStreak = 0
        }

        if result.outcome == .blackjack {
            updated.statistics.blackjacks += 1
        }

        updated.statistics.bestStreak = max(updated.statistics.bestStreak, updated.winStreak)

        let gainedXP = xpGain(for: result, streak: updated.winStreak, modifier: modifier)
        updated.xp += gainedXP

        while updated.xp >= levelThreshold(for: updated.level) {
            updated.xp -= levelThreshold(for: updated.level)
            updated.level += 1
            events.append(.levelUp)
        }

        let previousUnlocks = updated.unlockFlags
        updated.unlockFlags = resolveUnlocks(for: updated.level, existingUnlocks: previousUnlocks)
        let newUnlocks = updated.unlockFlags.subtracting(previousUnlocks)
        if !newUnlocks.isEmpty {
            events.append(.unlock)
        }

        return ProgressionDelta(profile: updated, events: events, unlocked: newUnlocks)
    }
}
