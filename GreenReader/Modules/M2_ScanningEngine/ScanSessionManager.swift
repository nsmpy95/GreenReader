import ARKit
import SceneKit
import SwiftUI

// MARK: - ScanSessionManager
// Owns the ARKit session lifecycle: configures, starts, and stops LiDAR scanning.
final class ScanSessionManager: NSObject {

    // MARK: - Private state

    private var meshAnchorHandler: MeshAnchorHandler?
    private var wireframeRenderer: WireframeRenderer?
    private var hardwareGuards: HardwareGuards?
    private weak var arView: ARSCNView?
    private weak var viewModel: ScanViewModel?

    // MARK: - Public API

    /// Configures and starts an ARKit LiDAR session on the supplied ARSCNView.
    func startScan(on arView: ARSCNView, viewModel: ScanViewModel) {
        self.arView   = arView
        self.viewModel = viewModel

        // Pre-flight battery check (non-blocking)
        let guards = HardwareGuards(viewModel: viewModel) { [weak self] in
            self?.stopScan()
        }
        hardwareGuards = guards
        guards.checkBattery()

        // Build sub-components
        let renderer = WireframeRenderer()
        wireframeRenderer = renderer

        let handler = MeshAnchorHandler(
            viewModel: viewModel,
            wireframeRenderer: renderer,
            stopScanCallback: { [weak self] in self?.stopScan() }
        )
        meshAnchorHandler = handler

        // Wire delegates before running the session
        arView.delegate         = handler
        arView.session.delegate = handler
        handler.hardwareGuards  = guards

        // Build ARKit configuration
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction     = .mesh
        config.environmentTexturing    = .automatic
        config.planeDetection          = [.horizontal]

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // Update state on main thread
        Task { @MainActor in
            viewModel.scanState = .scanning
        }
    }

    /// Pauses the AR session and transitions state to .processing, ready for M3.
    func stopScan() {
        arView?.session.pause()

        Task { @MainActor in
            viewModel?.scanState = .processing
        }
    }
}
