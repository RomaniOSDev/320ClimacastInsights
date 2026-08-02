import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject var store: AppDataStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    feedbackSection
                    reminderSection
                    smartAlertSection
                    themeSection

                    telemetryLink(title: "Rate Us", value: "OPEN", symbol: "star.fill") {
                        requestReview()
                    }
                    telemetryLink(title: "Privacy Policy", value: "LINK", symbol: "hand.raised.fill") {
                        openURL(AppLink.privacyPolicy)
                    }
                    telemetryLink(title: "Terms of Use", value: "LINK", symbol: "doc.text.fill") {
                        openURL(AppLink.termsOfUse)
                    }

                    Button {
                        showResetConfirm = true
                    } label: {
                        telemetryReadout(label: "Reset All Data", value: "WIPE", warning: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .screenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SYSTEM // SETTINGS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            .confirmationDialog("Reset all local data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                    HapticFeedback.warning()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var feedbackSection: some View {
        GlassPanel(accent: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("FEEDBACK // CONTROLS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color("AppPrimary"))

                feedbackToggle(
                    title: "Sound",
                    symbol: store.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    isOn: $store.soundEnabled
                ) {
                    if store.soundEnabled {
                        HapticFeedback.playCompleteSound()
                    }
                }

                feedbackToggle(
                    title: "Haptic Feedback",
                    symbol: store.hapticEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                    isOn: $store.hapticEnabled
                ) {
                    if store.hapticEnabled {
                        HapticFeedback.medium()
                    }
                }
            }
        }
    }

    private var reminderSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY REMINDER")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color("AppPrimary"))

                feedbackToggle(
                    title: "Remind me to log",
                    symbol: "bell.badge.fill",
                    isOn: Binding(
                        get: { store.reminderEnabled },
                        set: { newValue in
                            if newValue {
                                ReminderScheduler.requestAuthorization { granted in
                                    store.reminderEnabled = granted
                                    if granted {
                                        ReminderScheduler.reschedule(
                                            enabled: true,
                                            hour: store.reminderHour,
                                            minute: store.reminderMinute
                                        )
                                    }
                                }
                            } else {
                                store.reminderEnabled = false
                            }
                        }
                    )
                ) {}

                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { store.reminderDate },
                        set: { store.reminderDate = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .tint(Color("AppPrimary"))
                .disabled(!store.reminderEnabled)
                .opacity(store.reminderEnabled ? 1 : 0.45)

                Text("Local notification only. No account required.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private var smartAlertSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("SMART ALERT")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color("AppPrimary"))

                feedbackToggle(
                    title: "Consecutive days",
                    symbol: "exclamationmark.triangle.fill",
                    isOn: $store.smartAlertEnabled
                ) {}

                HStack {
                    Text("DAYS IN A ROW")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Spacer()
                    Text("\(store.smartAlertDays)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppAccent"))
                }

                Stepper(
                    value: Binding(
                        get: { store.smartAlertDays },
                        set: { store.smartAlertDays = min(max($0, 2), 14) }
                    ),
                    in: 2...14
                ) {
                    Text("Trigger after \(store.smartAlertDays) days above \(Int(store.cloudAlertThreshold))%")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .disabled(!store.smartAlertEnabled)
                .opacity(store.smartAlertEnabled ? 1 : 0.45)
            }
        }
    }

    private var themeSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("INSTRUMENT THEME")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color("AppPrimary"))

                ForEach(InstrumentTheme.allCases) { theme in
                    Button {
                        store.instrumentTheme = theme
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color("AppPrimary"))
                                .frame(width: 14, height: 14)
                                .hueRotation(.degrees(theme.hueDegrees))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.title.uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(0.8)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(theme.detail)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            Spacer()
                            Text(store.instrumentTheme == theme ? "ON" : "OFF")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(store.instrumentTheme == theme ? Color("AppAccent") : Color("AppTextSecondary"))
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func feedbackToggle(
        title: String,
        symbol: String,
        isOn: Binding<Bool>,
        onChange: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 22)

            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()

            Text(isOn.wrappedValue ? "ON" : "OFF")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(isOn.wrappedValue ? Color("AppAccent") : Color("AppTextSecondary"))

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color("AppPrimary"))
                .onChange(of: isOn.wrappedValue) { enabled in
                    if enabled { onChange() }
                }
        }
    }

    private func telemetryReadout(label: String, value: String, warning: Bool = false) -> some View {
        HStack(spacing: 8) {
            if warning {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("AppPrimary"))
            }
            Text(label.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Color("AppTextPrimary"))
            Text(String(repeating: "·", count: 16))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(warning ? Color("AppPrimary") : Color("AppAccent"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(HUDReadoutFrame(accent: warning))
    }

    private func telemetryLink(title: String, value: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 16)
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(String(repeating: "·", count: 16))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color("AppAccent"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(HUDReadoutFrame())
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            openURL("https://apps.apple.com")
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}
