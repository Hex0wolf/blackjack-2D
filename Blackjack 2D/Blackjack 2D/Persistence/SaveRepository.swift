import Foundation

protocol SaveRepository {
    func loadProfile() -> PlayerProfile
    func saveProfile(_ profile: PlayerProfile)
    func loadSettings() -> GameSettings
    func saveSettings(_ settings: GameSettings)
}

final class JSONSaveRepository: SaveRepository {
    private struct SaveEnvelope: Codable {
        var saveVersion: Int
        var profile: PlayerProfile
        var settings: GameSettings
        var updatedAt: Date
    }

    private let saveVersion = 1
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadProfile() -> PlayerProfile {
        loadEnvelope().profile
    }

    func saveProfile(_ profile: PlayerProfile) {
        var envelope = loadEnvelope()
        envelope.profile = profile
        envelope.settings = profile.settings
        persist(envelope)
    }

    func loadSettings() -> GameSettings {
        loadEnvelope().settings
    }

    func saveSettings(_ settings: GameSettings) {
        var envelope = loadEnvelope()
        envelope.settings = settings
        envelope.profile.settings = settings
        persist(envelope)
    }

    private func loadEnvelope() -> SaveEnvelope {
        let fallback = SaveEnvelope(
            saveVersion: saveVersion,
            profile: .default,
            settings: GameSettings(),
            updatedAt: Date()
        )

        let url = saveURL
        guard fileManager.fileExists(atPath: url.path) else {
            return fallback
        }

        do {
            let data = try Data(contentsOf: url)
            var decoded = try decoder.decode(SaveEnvelope.self, from: data)

            // Forward-safe fallback for unknown future versions.
            if decoded.saveVersion != saveVersion {
                decoded.saveVersion = saveVersion
            }

            decoded.profile.settings = decoded.settings
            return decoded
        } catch {
            backupCorruptedSave(from: url)
            return fallback
        }
    }

    private func persist(_ envelope: SaveEnvelope) {
        var updated = envelope
        updated.saveVersion = saveVersion
        updated.updatedAt = Date()

        do {
            let data = try encoder.encode(updated)
            try data.write(to: saveURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save profile: \(error)")
        }
    }

    private func backupCorruptedSave(from url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let backupName = "savegame-corrupt-\(formatter.string(from: Date())).json"
        let backupURL = url.deletingLastPathComponent().appendingPathComponent(backupName)
        _ = try? fileManager.copyItem(at: url, to: backupURL)
    }

    private var saveURL: URL {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return directory.appendingPathComponent("savegame.json")
    }
}
