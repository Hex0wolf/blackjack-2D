import Foundation

struct GameSettings: Codable {
    var musicEnabled: Bool = true
    var sfxEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var musicVolume: Double = 0.65
    var sfxVolume: Double = 0.8
    var textScale: Double = 1.0
    var tutorialCompleted: Bool = false
}
