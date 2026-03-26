import SwiftUI

// MARK: - ContentView
// Root container. Layers the AR camera view with state-driven overlays.
struct ContentView: View {

    @Environment(ScanViewModel.self) private var viewModel

    /// Tracks whether the onboarding sheet has been completed.
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "onboardingComplete")

    /// Tracks whether the settings sheet is presented.
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack {

            // MARK: Layer 1 — AR camera / LiDAR gate (fills edge-to-edge)
            LiDARGateView(viewModel: viewModel)
                .ignoresSafeArea()

            // MARK: Layer 2 — Scan guidance overlay (scanning state)
            if viewModel.scanState == .scanning {
                ScanGuidanceOverlay(viewModel: viewModel)
                    .transition(.opacity)
            }

            // MARK: Layer 3 — Processing spinner (processing state)
            if viewModel.scanState == .processing {
                ProcessingView()
                    .transition(.opacity)
            }

            // MARK: Layer 4 — Results overlay and legend (results state)
            if viewModel.scanState == .results {
                ResultsOverlay(viewModel: viewModel)
                    .transition(.opacity)

                SlopeLegend()
                    .transition(.opacity)
            }

            // MARK: Layer 5 — Warning banner (always present; shows when activeWarning != nil)
            WarningBanner(viewModel: viewModel)

            // MARK: Layer 6 — Bottom action bar (always present)
            BottomActionBar(viewModel: viewModel)

            // MARK: Layer 7 — Gear / settings button (top-left)
            VStack {
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.greenAccent)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)

                    Spacer()
                }
                Spacer()
            }
        }
        // MARK: Status bar
        .statusBarHidden(true)

        // MARK: State-transition animation
        .animation(.easeInOut(duration: 0.3), value: viewModel.scanState)

        // MARK: Settings sheet
        .sheet(isPresented: $showSettings) {
            SettingsSheet(viewModel: viewModel)
        }

        // MARK: Onboarding sheet
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}
