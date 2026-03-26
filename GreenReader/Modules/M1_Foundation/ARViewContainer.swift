import SwiftUI
import ARKit
import SceneKit

// MARK: - ARViewContainer
// UIViewRepresentable that hosts the ARSCNView for the AR camera feed.
// M2 is responsible for configuring and starting the AR session;
// this file only creates and exposes the view.
struct ARViewContainer: UIViewRepresentable {

    let viewModel: ScanViewModel

    // MARK: UIViewRepresentable

    /// Creates and configures the ARSCNView with automatic lighting enabled.
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.automaticallyUpdatesLighting = true

        // Store the ARSCNView on the ViewModel so M2 can access it.
        viewModel.arView = arView

        return arView
    }

    /// Updates are handled by M2 via the session delegate — nothing to do here.
    func updateUIView(_ uiView: ARSCNView, context: Context) { }
}
