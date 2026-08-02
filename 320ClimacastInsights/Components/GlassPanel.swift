import SwiftUI

struct GlassPanel<Content: View>: View {
    var accent: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color("AppBackground").opacity(0.72))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color("AppSurface").opacity(accent ? 0.35 : 0.22))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(accent ? 0.55 : 0.28), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color("AppTextSecondary").opacity(0.35), lineWidth: 0.5)
                        .padding(3)
                    InstrumentCrosshairs(accent: accent)
                }
            )
    }
}

private struct InstrumentCrosshairs: View {
    var accent: Bool

    var body: some View {
        GeometryReader { geo in
            let len: CGFloat = 10
            let inset: CGFloat = 5
            let color = Color("AppPrimary").opacity(accent ? 0.75 : 0.4)
            Canvas { context, size in
                var path = Path()
                // top-leading
                path.move(to: CGPoint(x: inset, y: inset + len))
                path.addLine(to: CGPoint(x: inset, y: inset))
                path.addLine(to: CGPoint(x: inset + len, y: inset))
                // top-trailing
                path.move(to: CGPoint(x: size.width - inset - len, y: inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: inset + len))
                // bottom-leading
                path.move(to: CGPoint(x: inset, y: size.height - inset - len))
                path.addLine(to: CGPoint(x: inset, y: size.height - inset))
                path.addLine(to: CGPoint(x: inset + len, y: size.height - inset))
                // bottom-trailing
                path.move(to: CGPoint(x: size.width - inset - len, y: size.height - inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
                path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset - len))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}
