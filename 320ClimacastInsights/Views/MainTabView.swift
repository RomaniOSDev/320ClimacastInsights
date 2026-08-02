import SwiftUI

struct MainTabView: View {
    @ObservedObject var store: AppDataStore

    private var tabBar: FloatingTabBar {
        FloatingTabBar(selectedTab: $store.selectedTab) {
            store.selectedTab = .sky
            NotificationCenter.default.post(name: .openLogNow, object: nil)
        }
    }

    private var bannerHitTesting: Bool {
        store.pendingAlertBanner != nil
            || store.pendingAchievementBanner != nil
            || store.pendingTip != nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch store.selectedTab {
                case .sky:
                    SkyTrackerView(store: store)
                case .log:
                    CloudLogView(store: store)
                case .insights:
                    InsightsView(store: store)
                case .settings:
                    SettingsView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 78)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 88)
            }
            .overlay(alignment: .top) {
                tabBar
            }
            .overlay(alignment: .bottomTrailing) {
                tabBar.logFAB
                    .padding(.trailing, 20)
                    .padding(.bottom, 18)
            }

            VStack(spacing: 8) {
                Color.clear.frame(height: 78)
                if let alert = store.pendingAlertBanner {
                    AlertBannerView(message: alert) {
                        withAnimation { store.dismissAlertBanner() }
                    }
                }
                if let achievement = store.pendingAchievementBanner {
                    AchievementBannerView(achievement: achievement) {
                        withAnimation { store.dismissAchievementBanner() }
                    }
                }
                if store.pendingAchievementBanner == nil, let tip = store.pendingTip {
                    TipBannerView(tip: tip) {
                        withAnimation { store.dismissTip() }
                    }
                }
                Spacer(minLength: 0)
            }
            .allowsHitTesting(bannerHitTesting)
        }
        .ignoresSafeArea(.keyboard)
        .dismissKeyboardOnTap()
        .hueRotation(.degrees(store.instrumentTheme.hueDegrees))
        .animation(.easeInOut(duration: 0.25), value: store.instrumentTheme)
        .onAppear {
            store.evaluateTips()
        }
    }
}
