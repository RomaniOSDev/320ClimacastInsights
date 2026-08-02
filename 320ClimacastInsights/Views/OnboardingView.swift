import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: AppDataStore
    @State private var page = 0

    private let pages: [(title: String, body: String, symbol: String)] = [
        (
            "Monitor Clouds",
            "Keep track of current cloud cover to make informed decisions about outdoor activities.",
            "cloud.sun.fill"
        ),
        (
            "Set Alerts",
            "Customize alerts to notify you when cloud coverage reaches your chosen levels.",
            "bell.badge.fill"
        ),
        (
            "Begin Tracking",
            "Start using the real-time tracker to monitor and analyze local cloud patterns.",
            "scope"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: page)

            Button {
                HapticFeedback.medium()
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    store.hasSeenOnboarding = true
                }
            } label: {
                Text((page < pages.count - 1 ? "Continue" : "Get Started").uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color("AppBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BezelCTABackground())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .screenBackground()
    }

    private func onboardingPage(_ item: (title: String, body: String, symbol: String), index: Int) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 36)

            Text("INSTRUMENT \(String(format: "%02d", index + 1)) // BOOT")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(Color("AppAccent"))

            GlassPanel(accent: true) {
                VStack(spacing: 18) {
                    HorizonGraphic()

                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color("AppPrimary").opacity(0.55), lineWidth: 1)
                            .frame(width: 88, height: 88)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color("AppTextSecondary").opacity(0.35), lineWidth: 0.5)
                            .frame(width: 76, height: 76)
                        Image(systemName: item.symbol)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }

                    VStack(spacing: 10) {
                        Text(item.title.uppercased())
                            .font(.system(size: 22, weight: .bold))
                            .tracking(1.8)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .multilineTextAlignment(.center)

                        Text(item.body)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

struct BezelCTABackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color("AppPrimary"))
            Canvas { context, size in
                let len: CGFloat = 10
                let inset: CGFloat = 4
                var path = Path()
                path.move(to: CGPoint(x: inset, y: inset + len))
                path.addLine(to: CGPoint(x: inset, y: inset))
                path.addLine(to: CGPoint(x: inset + len, y: inset))
                path.move(to: CGPoint(x: size.width - inset - len, y: inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: inset + len))
                path.move(to: CGPoint(x: inset, y: size.height - inset - len))
                path.addLine(to: CGPoint(x: inset, y: size.height - inset))
                path.addLine(to: CGPoint(x: inset + len, y: size.height - inset))
                path.move(to: CGPoint(x: size.width - inset - len, y: size.height - inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset - len))
                context.stroke(path, with: .color(Color("AppBackground").opacity(0.55)), lineWidth: 1.5)
            }
        }
    }
}
