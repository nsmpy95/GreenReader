import SwiftUI

// MARK: - SlopeLegend
// Persistent bottom-left colour legend shown alongside ResultsOverlay
// during the .results state.
struct SlopeLegend: View {

    var body: some View {
        VStack {
            Spacer()

            HStack {
                // MARK: Legend card
                VStack(alignment: .leading, spacing: 6) {
                    LegendRow(color: .slopeFlat,     label: "Flat (0–1°)")
                    LegendRow(color: .slopeSubtle,   label: "Subtle (1–2°)")
                    LegendRow(color: .slopeModerate, label: "Moderate (2–4°)")
                    LegendRow(color: .slopeSevere,   label: "Severe (4°+)")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Color.black.opacity(0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                )
                .padding(.leading, 16)
                .padding(.bottom, 16)

                Spacer()
            }
        }
        // Slide-up entrance to match ResultsOverlay
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: true)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - LegendRow
/// Single row: colour swatch + text label.
private struct LegendRow: View {

    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }
}
