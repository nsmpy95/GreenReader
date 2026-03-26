import SwiftUI

// MARK: - WarningBanner
// Amber slide-down banner that surfaces viewModel.activeWarning messages.
// Auto-dismisses after 4 seconds; tap dismisses immediately.
struct WarningBanner: View {

    @Bindable var viewModel: ScanViewModel

    // Controls whether the banner is visually presented.
    @State private var isVisible: Bool = false

    // Cancels any in-flight auto-dismiss task when the warning changes.
    @State private var dismissTask: Task<Void, Never>? = nil

    var body: some View {
        VStack {
            if isVisible, let warning = viewModel.activeWarning {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 16, weight: .semibold))

                    Text(warning)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.warningAmber)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    dismiss()
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        // React to new warnings being set on the ViewModel.
        .onChange(of: viewModel.activeWarning) { _, newWarning in
            if newWarning != nil {
                showBanner()
            } else {
                isVisible = false
            }
        }
    }

    // MARK: - Helpers

    private func showBanner() {
        // Cancel any prior auto-dismiss in flight.
        dismissTask?.cancel()
        isVisible = true

        dismissTask = Task {
            do {
                // 4-second auto-dismiss (sleep accepts nanoseconds).
                try await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { dismiss() }
            } catch {
                // Task was cancelled — nothing to do.
            }
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        isVisible = false
        viewModel.activeWarning = nil
    }
}
