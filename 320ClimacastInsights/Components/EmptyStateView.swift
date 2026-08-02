import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var secondarySystemImage: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    for i in 1...3 {
                        let r = CGFloat(14 + i * 14)
                        context.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .color(Color("AppPrimary").opacity(0.2)),
                            lineWidth: 0.8
                        )
                    }
                }
                .frame(width: 100, height: 100)

                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                    if let secondarySystemImage {
                        Image(systemName: secondarySystemImage)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(HUDReadoutFrame())

            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
