import Foundation
@testable import Blackjack_2D

final class InMemorySaveRepository: SaveRepository {
    private var storedProfile: PlayerProfile
    private var storedSettings: GameSettings

    init(profile: PlayerProfile = .default, settings: GameSettings = GameSettings()) {
        var mergedProfile = profile
        mergedProfile.settings = settings
        storedProfile = mergedProfile
        storedSettings = settings
    }

    func loadProfile() -> PlayerProfile {
        storedProfile
    }

    func saveProfile(_ profile: PlayerProfile) {
        storedProfile = profile
        storedSettings = profile.settings
    }

    func loadSettings() -> GameSettings {
        storedSettings
    }

    func saveSettings(_ settings: GameSettings) {
        storedSettings = settings
        storedProfile.settings = settings
    }
}

final class SilentAudioService: AudioService {
    func playSFX(_ key: SFXKey) {}
    func playMusic(_ track: MusicTrack) {}
    func duckMusic(for duration: TimeInterval) {}
    func setMix(settings: GameSettings) {}
}

final class SilentHapticService: HapticService {
    func notify(event: RoundEvent, enabled: Bool) {}
    func tap(enabled: Bool) {}
}

final class QueuedShoeProvider: ShoeProviding {
    private var shoes: [[Card]]

    init(shoes: [[Card]]) {
        self.shoes = shoes
    }

    func makeShoe() -> [Card] {
        if shoes.isEmpty {
            return DeckFactory.makeShuffledShoe(deckCount: 1, seed: 777)
        }
        return shoes.removeFirst()
    }
}
