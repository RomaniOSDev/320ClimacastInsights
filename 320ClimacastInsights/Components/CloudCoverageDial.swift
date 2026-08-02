import SwiftUI

struct CloudCoverageDial: View {
    var coverage: Double
    var animated: Bool = true

    @State private var displayCoverage: Double = 0

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 8

                context.fill(
                    Path(ellipseIn: CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                    with: .color(Color("AppBackground").opacity(0.85))
                )

                for i in 1...4 {
                    let r = radius * CGFloat(i) / 4
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(Color("AppPrimary").opacity(0.18 + Double(i) * 0.04)),
                        lineWidth: 0.8
                    )
                }

                for deg in stride(from: 0.0, through: 350.0, by: 10.0) {
                    let rad = (deg - 90) * .pi / 180
                    let major = deg.truncatingRemainder(dividingBy: 30) == 0
                    let outer = radius
                    let inner = radius - (major ? 10 : 5)
                    var tick = Path()
                    tick.move(to: CGPoint(
                        x: center.x + cos(rad) * inner,
                        y: center.y + sin(rad) * inner
                    ))
                    tick.addLine(to: CGPoint(
                        x: center.x + cos(rad) * outer,
                        y: center.y + sin(rad) * outer
                    ))
                    context.stroke(
                        tick,
                        with: .color(Color("AppTextSecondary").opacity(major ? 0.7 : 0.35)),
                        lineWidth: major ? 1.2 : 0.6
                    )
                }

                let fraction = min(max(displayCoverage / 100, 0), 1)
                var arc = Path()
                arc.addArc(
                    center: center,
                    radius: radius - 16,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * fraction),
                    clockwise: false
                )
                context.stroke(arc, with: .color(Color("AppPrimary")), lineWidth: 4)

                let tipAngle = (-90 + 360 * fraction) * .pi / 180
                let tipR = radius - 16
                let tip = CGPoint(
                    x: center.x + cos(tipAngle) * tipR,
                    y: center.y + sin(tipAngle) * tipR
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: tip.x - 3.5, y: tip.y - 3.5, width: 7, height: 7)),
                    with: .color(Color("AppAccent"))
                )

                let hub = Path(ellipseIn: CGRect(
                    x: center.x - radius * 0.42,
                    y: center.y - radius * 0.42,
                    width: radius * 0.84,
                    height: radius * 0.84
                ))
                context.fill(hub, with: .color(Color("AppBackground").opacity(0.92)))
                context.stroke(hub, with: .color(Color("AppTextSecondary").opacity(0.35)), lineWidth: 0.5)
            }

            VStack(spacing: 2) {
                Text("\(Int(displayCoverage.rounded()))%")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("CLOUD COVER")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            updateDisplay(coverage)
        }
        .onChange(of: coverage) { newValue in
            updateDisplay(newValue)
        }
    }

    private func updateDisplay(_ value: Double) {
        if animated {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                displayCoverage = value
            }
        } else {
            displayCoverage = value
        }
    }
}
