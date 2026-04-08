import SwiftUI

struct CPUIndicatorView: View {
    @ObservedObject var viewModel: CPUIndicatorViewModel

    var body: some View {
        let displayFontSize = viewModel.displayFontSize

        ZStack {
            CPUArcShape(trimFraction: 0.75)
                .stroke(
                    .primary.opacity(viewModel.trackOpacity),
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            CPUArcShape(trimFraction: max(0.02, 0.75 * viewModel.progress))
                .stroke(
                    .primary.opacity(viewModel.activeOpacity),
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            Text(viewModel.displayText)
                .font(.system(size: displayFontSize, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundStyle(.primary.opacity(viewModel.textOpacity))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
                .frame(width: 17, height: 17, alignment: .center)
        }
        .frame(width: 18, height: 18)
        .animation(.easeOut(duration: 0.2), value: viewModel.progress)
        .animation(.easeOut(duration: 0.2), value: viewModel.displayText)
        .allowsHitTesting(false)
    }
}

private struct CPUArcShape: Shape {
    var trimFraction: Double

    func path(in rect: CGRect) -> Path {
        let clampedFraction = max(0, min(0.75, trimFraction))
        let insetRect = rect.insetBy(dx: 0.75, dy: 0.75)

        var path = Path()
        path.addArc(
            center: CGPoint(x: insetRect.midX, y: insetRect.midY),
            radius: min(insetRect.width, insetRect.height) / 2,
            startAngle: .degrees(135),
            endAngle: .degrees(135 + (360 * clampedFraction)),
            clockwise: false
        )
        return path
    }
}
