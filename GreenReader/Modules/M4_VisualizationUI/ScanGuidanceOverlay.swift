import SwiftUI

// MARK: - ScanGuidanceOverlay
// Floating guidance shown only while scanState == .scanning.
// Includes an instructional label, a coverage progress bar, and
// light haptic feedback throttled to at most once per second.
struct ScanGuidanceOverlay: View {

    @Bindable var viewModel: ScanViewModel

    // Haptic generator — created once, reused for every pulse.
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // Tracks the timestamp of the last haptic so we honour the 1-second throttle.
    @State private var lastHapticDate: Date = .distantPast

    // Derived coverage fraction in [0, 1].
    private var coverage: Double {
        min(1.0, Double(viewModel.meshData.count) / 10_000.0)
    }

    var body: some View {
        VStack(spacing: 8) {

            // MARK: Instruction label
            Text("Move slowly across the green")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5), in: Capsule())
                .padding(.top, 4)  // sits just below the safe area top anchor

            // MARK: Coverage progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 4)

                    // Fill
                    Capsule()
                        .fill(Color.greenAccent)
                        .frame(width: geometry.size.width * coverage, height: 4)
                        .animation(.linear(duration: 0.5), value: coverage)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 0) // ZStack root — safe area handled by .safeAreaInset on the parent
        .animation(.easeInOut(duration: 0.3), value: viewModel.scanState)

        // MARK: Haptic feedback on mesh chunk arrival
        .onChange(of: viewModel.meshData.count) { _, _ in
            guard viewModel.hapticsEnabled else { return }
            let now = Date()
            guard now.timeIntervalSince(lastHapticDate) >= 1.0 else { return }
            lastHapticDate = now
            hapticGenerator.impactOccurred()
        }
        .safeAreaInset(edge: .top) {
            // Reserve space so the content sits below the Dynamic Island / notch.
            Color.clear.frame(height: 0)
        }
    }
}
