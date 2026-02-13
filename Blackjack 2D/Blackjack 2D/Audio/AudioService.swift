import AVFoundation
import Foundation
import os

protocol AudioService {
    func playSFX(_ key: SFXKey)
    func playMusic(_ track: MusicTrack)
    func duckMusic(for duration: TimeInterval)
    func setMix(settings: GameSettings)
}

final class DefaultAudioService: AudioService {
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [SFXKey: AVAudioPlayer] = [:]
    private var settings = GameSettings()
    private static let logger = Logger(subsystem: "com.ethangraham.Blackjack-2D", category: "audio")
    private static var missingResources: Set<String> = []

    init() {
        configureSession()
    }

    func playSFX(_ key: SFXKey) {
        guard settings.sfxEnabled else { return }

        if let player = sfxPlayers[key] {
            player.currentTime = 0
            player.play()
            return
        }

        guard let player = loadPlayer(resourceName: key.rawValue, fileExtension: "wav") else {
            return
        }

        player.volume = Float(settings.sfxVolume)
        sfxPlayers[key] = player
        player.play()
    }

    func playMusic(_ track: MusicTrack) {
        guard settings.musicEnabled else {
            musicPlayer?.stop()
            return
        }

        if musicPlayer?.url?.lastPathComponent == "\(track.rawValue).mp3" {
            if musicPlayer?.isPlaying == false {
                musicPlayer?.play()
            }
            return
        }

        guard let player = loadPlayer(resourceName: track.rawValue, fileExtension: "mp3") else {
            return
        }

        player.numberOfLoops = -1
        player.volume = Float(settings.musicVolume)
        musicPlayer = player
        player.play()
    }

    func duckMusic(for duration: TimeInterval) {
        guard let musicPlayer else { return }
        let original = musicPlayer.volume
        musicPlayer.setVolume(original * 0.35, fadeDuration: 0.1)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak musicPlayer] in
            musicPlayer?.setVolume(original, fadeDuration: 0.2)
        }
    }

    func setMix(settings: GameSettings) {
        self.settings = settings
        musicPlayer?.volume = Float(settings.musicVolume)
        sfxPlayers.values.forEach { $0.volume = Float(settings.sfxVolume) }
        if !settings.musicEnabled {
            musicPlayer?.stop()
        }
    }

    private func loadPlayer(resourceName: String, fileExtension: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            logMissingResource("\(resourceName).\(fileExtension)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            Self.logger.error("Failed to initialize audio resource \(resourceName, privacy: .public).\(fileExtension, privacy: .public): \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    private func logMissingResource(_ resource: String) {
        guard Self.missingResources.insert(resource).inserted else { return }
        Self.logger.warning("Missing audio resource: \(resource, privacy: .public). Gameplay continues with silent fallback.")
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silent fail keeps gameplay alive even without audio session setup.
        }
    }
}
