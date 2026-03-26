import SwiftUI

// MARK: - SettingsSheet
// Modal settings panel presented from the gear icon in ContentView.
struct SettingsSheet: View {

    @Bindable var viewModel: ScanViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showingOnboarding = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Preferences
                Section("Preferences") {
                    Toggle("Haptic Feedback", isOn: $viewModel.hapticsEnabled)
                }

                // MARK: Device
                Section("Device") {
                    deviceRow(label: "Model", value: UIDevice.current.model)
                    deviceRow(label: "LiDAR", value: "Available")
                }

                // MARK: Help
                Section("Help") {
                    Button("How to scan") {
                        showingOnboarding = true
                    }
                    .foregroundStyle(Color.greenAccent)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.greenAccent)
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
        }
    }

    // MARK: - Helpers

    /// Renders a label + value info row for the Device section.
    @ViewBuilder
    private func deviceRow(label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
