import SwiftUI

struct AchievementBannerView: View {
    let achievement: AchievementID
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 36, height: 36)
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.7), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("ACHIEVEMENT // UNLOCKED")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppAccent"))
                Text(achievement.title.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(HUDReadoutFrame(accent: true))
        .padding(.horizontal, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            HapticFeedback.success()
            HapticFeedback.playSuccessSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                onDismiss()
            }
        }
    }
}

struct TipBannerView: View {
    let tip: CoachTip
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 36, height: 36)
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.7), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color("AppAccent"))
                Text(tip.message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(HUDReadoutFrame(accent: false))
        .padding(.horizontal, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct AlertBannerView: View {
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 36, height: 36)
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.7), lineWidth: 1)
                }

            Text(message.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color("AppTextPrimary"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(HUDReadoutFrame(accent: false))
        .padding(.horizontal, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                onDismiss()
            }
        }
    }
}

struct HUDReadoutFrame: View {
    var accent: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color("AppBackground").opacity(0.92))
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color("AppPrimary").opacity(accent ? 0.7 : 0.45), lineWidth: 1)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color("AppTextSecondary").opacity(0.35), lineWidth: 0.5)
                .padding(3)
        }
    }
}
