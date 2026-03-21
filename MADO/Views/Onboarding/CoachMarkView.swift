import SwiftUI

struct CoachMarkView: View {
    let text: String
    var position: Edge = .bottom
    var showPulse: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 8) {
            if position == .bottom {
                arrow(pointing: .up)
            }

            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "4CA6E8"))
                )
                .scaleEffect(isPulsing && showPulse ? 1.03 : 1.0)

            if position == .top {
                arrow(pointing: .down)
            }
        }
        .onAppear {
            guard !reduceMotion, showPulse else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel(text)
    }

    private func arrow(pointing direction: VerticalDirection) -> some View {
        Image(systemName: direction == .up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
            .font(.caption)
            .foregroundStyle(Color(hex: "4CA6E8"))
    }

    private enum VerticalDirection {
        case up, down
    }
}
