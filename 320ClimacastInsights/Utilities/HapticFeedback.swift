import UIKit
import AudioToolbox

enum HapticFeedback {
    private static var hapticsEnabled: Bool {
        AppDataStore.shared.hapticEnabled
    }

    private static var soundEnabled: Bool {
        AppDataStore.shared.soundEnabled
    }

    static func light() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func soft() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func playCompleteSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func playSuccessSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1103)
    }

    static func playAlertSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1054)
    }
}
