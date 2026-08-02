import SwiftUI

struct HorizonGraphic: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
            let maxR = min(size.width, size.height) * 0.46

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color("AppBackground").opacity(0.55))
            )

            for i in 1...4 {
                let r = maxR * CGFloat(i) / 4
                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Color("AppPrimary").opacity(0.22 + Double(i) * 0.05)),
                    lineWidth: i == 4 ? 1.2 : 0.7
                )
            }

            var spokes = Path()
            for deg in stride(from: 0.0, through: 330.0, by: 30.0) {
                let rad = deg * .pi / 180
                let outer = CGPoint(
                    x: center.x + cos(rad) * maxR,
                    y: center.y + sin(rad) * maxR
                )
                let inner = CGPoint(
                    x: center.x + cos(rad) * maxR * 0.82,
                    y: center.y + sin(rad) * maxR * 0.82
                )
                spokes.move(to: inner)
                spokes.addLine(to: outer)
            }
            context.stroke(spokes, with: .color(Color("AppTextSecondary").opacity(0.45)), lineWidth: 1)

            var cross = Path()
            cross.move(to: CGPoint(x: center.x - maxR - 4, y: center.y))
            cross.addLine(to: CGPoint(x: center.x + maxR + 4, y: center.y))
            cross.move(to: CGPoint(x: center.x, y: center.y - maxR - 4))
            cross.addLine(to: CGPoint(x: center.x, y: center.y + maxR + 4))
            context.stroke(cross, with: .color(Color("AppPrimary").opacity(0.35)), lineWidth: 0.8)

            let blip = CGRect(x: center.x + maxR * 0.35, y: center.y - maxR * 0.42, width: 6, height: 6)
            context.fill(Path(ellipseIn: blip), with: .color(Color("AppAccent")))

            let labels = ["000", "090", "180", "270"]
            let positions: [CGPoint] = [
                CGPoint(x: center.x, y: center.y - maxR - 2),
                CGPoint(x: center.x + maxR + 2, y: center.y),
                CGPoint(x: center.x, y: center.y + maxR + 2),
                CGPoint(x: center.x - maxR - 2, y: center.y)
            ]
            let anchors: [UnitPoint] = [.bottom, .leading, .top, .trailing]
            for i in 0..<4 {
                let text = Text(labels[i])
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("AppTextSecondary"))
                context.draw(text, at: positions[i], anchor: anchors[i])
            }
        }
        .frame(height: 120)
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color("AppTextSecondary").opacity(0.3), lineWidth: 0.5)
                .padding(3)
        }
    }
}
