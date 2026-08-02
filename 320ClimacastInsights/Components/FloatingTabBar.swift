import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: MainTab
    var onLogNow: () -> Void

    private let tabs: [MainTab] = [.sky, .log, .insights, .settings]

    var body: some View {
        instrumentStrip
    }

    var logFAB: some View {
        Button(action: {
            HapticFeedback.medium()
            onLogNow()
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(Color("AppBackground"))
                        .frame(width: 58, height: 58)
                    Circle()
                        .stroke(Color("AppPrimary"), lineWidth: 1.5)
                        .frame(width: 58, height: 58)
                    Circle()
                        .stroke(Color("AppTextSecondary").opacity(0.45), lineWidth: 0.5)
                        .frame(width: 50, height: 50)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color("AppPrimary"))
                }
                .shadow(color: Color("AppBackground").opacity(0.55), radius: 2, y: 1)
                Text("LOG NOW")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppAccent"))
            }
        }
        .buttonStyle(.plain)
    }

    private var instrumentStrip: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                stripSegment(tab)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color("AppBackground").opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.55), lineWidth: 1)
                }
        )
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(Color("AppBackground").opacity(0.78))
    }

    private func stripSegment(_ tab: MainTab) -> some View {
        let selected = selectedTab == tab
        return Button {
            HapticFeedback.light()
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 14, weight: .semibold))
                Text(tab.title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
            }
            .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextSecondary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if selected {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color("AppPrimary"))
                        Canvas { context, size in
                            var path = Path()
                            var y: CGFloat = 0
                            while y < size.height {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                                y += 3
                            }
                            context.stroke(path, with: .color(Color("AppBackground").opacity(0.12)), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color("AppPrimary").opacity(selected ? 0 : 0.25), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}
