import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Color("AppBackground")
                    Image("bgSky")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.12)
                        .clipped()
                    RadarAtmosphereOverlay()
                }
                .ignoresSafeArea()
            }
    }
}

private struct RadarAtmosphereOverlay: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.42)
            let maxR = max(size.width, size.height) * 0.72

            for i in 1...5 {
                let r = maxR * CGFloat(i) / 5
                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Color("AppPrimary").opacity(0.06 + Double(i) * 0.01)),
                    lineWidth: 0.8
                )
            }

            var cross = Path()
            cross.move(to: CGPoint(x: center.x - maxR, y: center.y))
            cross.addLine(to: CGPoint(x: center.x + maxR, y: center.y))
            cross.move(to: CGPoint(x: center.x, y: center.y - maxR))
            cross.addLine(to: CGPoint(x: center.x, y: center.y + maxR))
            context.stroke(cross, with: .color(Color("AppPrimary").opacity(0.05)), lineWidth: 0.6)

            var scan = Path()
            var y: CGFloat = 0
            while y < size.height {
                scan.move(to: CGPoint(x: 0, y: y))
                scan.addLine(to: CGPoint(x: size.width, y: y))
                y += 4
            }
            context.stroke(scan, with: .color(Color("AppTextPrimary").opacity(0.03)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
