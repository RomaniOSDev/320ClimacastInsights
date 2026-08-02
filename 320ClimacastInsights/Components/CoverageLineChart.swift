import SwiftUI

struct CoverageLineChart: View {
    let points: [CloudHistoryPoint]

    var body: some View {
        Canvas { context, size in
            guard points.count >= 2 else {
                let mid = CGPoint(x: size.width / 2, y: size.height / 2)
                let text = Text("NOT ENOUGH POINTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("AppTextSecondary"))
                context.draw(text, at: mid, anchor: .center)
                return
            }

            let values = points.map(\.coverage)
            let minV = min(values.min() ?? 0, 0)
            let maxV = max(values.max() ?? 100, 1)
            let padL: CGFloat = 28
            let padR: CGFloat = 12
            let padT: CGFloat = 12
            let padB: CGFloat = 16
            let plotW = size.width - padL - padR
            let plotH = size.height - padT - padB

            func point(at index: Int) -> CGPoint {
                let x = padL + plotW * CGFloat(index) / CGFloat(points.count - 1)
                let norm = (points[index].coverage - minV) / (maxV - minV)
                let y = padT + plotH * (1 - CGFloat(norm))
                return CGPoint(x: x, y: y)
            }

            var grid = Path()
            for i in 0..<5 {
                let y = padT + plotH * CGFloat(i) / 4
                grid.move(to: CGPoint(x: padL, y: y))
                grid.addLine(to: CGPoint(x: size.width - padR, y: y))
                let labelVal = Int(maxV - (maxV - minV) * Double(i) / 4)
                let label = Text("\(labelVal)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("AppTextSecondary"))
                context.draw(label, at: CGPoint(x: padL - 4, y: y), anchor: .trailing)
            }
            for i in 0..<points.count {
                let x = padL + plotW * CGFloat(i) / CGFloat(points.count - 1)
                grid.move(to: CGPoint(x: x, y: padT))
                grid.addLine(to: CGPoint(x: x, y: size.height - padB))
            }
            context.stroke(grid, with: .color(Color("AppTextSecondary").opacity(0.18)), lineWidth: 0.6)

            var border = Path(CGRect(x: padL, y: padT, width: plotW, height: plotH))
            context.stroke(border, with: .color(Color("AppPrimary").opacity(0.4)), lineWidth: 1)

            var line = Path()
            line.move(to: point(at: 0))
            for i in 1..<points.count {
                line.addLine(to: point(at: i))
            }
            context.stroke(line, with: .color(Color("AppPrimary")), lineWidth: 1.8)

            for i in 0..<points.count {
                let p = point(at: i)
                let crossSize: CGFloat = 4
                var cross = Path()
                cross.move(to: CGPoint(x: p.x - crossSize, y: p.y))
                cross.addLine(to: CGPoint(x: p.x + crossSize, y: p.y))
                cross.move(to: CGPoint(x: p.x, y: p.y - crossSize))
                cross.addLine(to: CGPoint(x: p.x, y: p.y + crossSize))
                context.stroke(cross, with: .color(Color("AppAccent")), lineWidth: 1.2)
            }
        }
        .frame(height: 180)
    }
}
