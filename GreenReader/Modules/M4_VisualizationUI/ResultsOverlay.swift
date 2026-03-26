import SwiftUI

// MARK: - ResultsOverlay
// Floating info card shown in the top-right corner once scanState == .results.
// Displays max and average slope angles computed by M3.
struct ResultsOverlay: View {

    let viewModel: ScanViewModel

    var body: some View {
        VStack {
            HStack {
                Spacer()

                // MARK: Stats card
                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "Max slope: %.1f°", viewModel.maxSlope))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text(String(format: "Avg slope: %.1f°", viewModel.avgSlope))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(12)
                .background(
                    Color.black.opacity(0.6)
                        .clipShape(RoundedRectangle(cornerRadius: .cornerMd, style: .continuous))
                )
                .padding(.trailing, 16)
            }

            Spacer()
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        // Slide-up from bottom combined with opacity
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.scanState)
    }
}
