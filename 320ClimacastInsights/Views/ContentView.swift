import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView(store: store)
            } else {
                OnboardingView(store: store)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: store.hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.25), value: store.instrumentTheme)
    }
}
