import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                KeyboardDismiss.resign()
            }
        )
    }
}
