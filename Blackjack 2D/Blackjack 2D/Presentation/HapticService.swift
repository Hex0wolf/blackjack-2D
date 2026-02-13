import UIKit

protocol HapticService {
    func notify(event: RoundEvent, enabled: Bool)
    func tap(enabled: Bool)
}

final class DefaultHapticService: HapticService {
    func notify(event: RoundEvent, enabled: Bool) {
        guard enabled else { return }

        switch event {
        case .blackjack, .levelUp:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .playerWin, .unlock:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .dealerWin, .bust:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        default:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func tap(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
