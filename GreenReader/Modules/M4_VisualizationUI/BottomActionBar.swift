import SwiftUI

// MARK: - BottomActionBar
// Translucent bottom bar with a single large action button whose appearance
// and behaviour adapt to the current ScanState.
struct BottomActionBar: View {

    @Bindable var viewModel: ScanViewModel
    let onStartScan: () -> Void
    let onStopScan:  () -> Void

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                // Translucent background bar
                Color.black.opacity(0.6)
                    .frame(height: .bottomBarH)
                    .ignoresSafeArea(edges: .bottom)

                // Action button
                VStack(spacing: 4) {
                    Button(action: primaryAction) {
                        ZStack {
                            Circle()
                                .fill(buttonFillColor)
                                .frame(width: .buttonSize, height: .buttonSize)

                            Image(systemName: buttonIcon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .disabled(viewModel.scanState == .processing)
                    .frame(minWidth: .buttonSize, minHeight: .buttonSize) // ensure 60pt tap target
                    .animation(.easeInOut(duration: 0.3), value: viewModel.scanState)

                    Text(buttonLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .opacity(viewModel.scanState == .processing ? 0.4 : 1)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.scanState)
                }
                .padding(.bottom, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
    }

    // MARK: - State-derived properties

    private var primaryAction: () -> Void {
        switch viewModel.scanState {
        case .idle:       return onStartScan
        case .scanning:   return onStopScan
        case .processing: return { }              // disabled
        case .results:    return viewModel.resetToIdle
        }
    }

    private var buttonFillColor: Color {
        switch viewModel.scanState {
        case .idle:       return .greenAccent
        case .scanning:   return Color(red: 0.9, green: 0.15, blue: 0.15)   // red
        case .processing: return Color.gray.opacity(0.6)
        case .results:    return .greenAccent
        }
    }

    private var buttonIcon: String {
        switch viewModel.scanState {
        case .idle:       return "viewfinder"
        case .scanning:   return "stop.fill"
        case .processing: return "ellipsis"
        case .results:    return "arrow.counterclockwise"
        }
    }

    private var buttonLabel: String {
        switch viewModel.scanState {
        case .idle:       return "Start Scan"
        case .scanning:   return "Stop Scan"
        case .processing: return ""
        case .results:    return "Scan Again"
        }
    }
}
