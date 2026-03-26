import SwiftUI
import ARKit

// MARK: - LiDARGateView
// Guards entry into the AR experience by checking for LiDAR hardware.
// Shows a clear error UI on unsupported devices; passes through to ARViewContainer otherwise.
struct LiDARGateView: View {

    let viewModel: ScanViewModel

    /// Returns true when the device supports LiDAR scene reconstruction.
    private var isLiDARSupported: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    var body: some View {
        if isLiDARSupported {
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()
        } else {
            unsupportedDeviceView
        }
    }

    // MARK: - Unsupported device error view
    private var unsupportedDeviceView: some View {
        ZStack {
            Color.darkBg
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "sensor.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.greenAccent)

                Text("LiDAR sensor required")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("This app requires an iPhone with LiDAR")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
    }
}
