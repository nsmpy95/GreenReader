import ARKit
import SceneKit
import simd

// MARK: - MeshAnchorHandler
// ARSCNViewDelegate + ARSessionDelegate that extracts mesh geometry from ARMeshAnchors
// and appends structured MeshData to the shared ViewModel.
final class MeshAnchorHandler: NSObject {

    // MARK: - Dependencies

    private weak var viewModel: ScanViewModel?
    private weak var wireframeRenderer: WireframeRenderer?
    private let stopScanCallback: () -> Void

    /// Injected after construction to avoid a circular init dependency.
    var hardwareGuards: HardwareGuards?

    // MARK: - Throttle state (5 fps = 0.2 s minimum gap)

    private var lastRebuildDate: Date = .distantPast
    private let rebuildInterval: TimeInterval = 0.2

    // MARK: - Init

    init(
        viewModel: ScanViewModel,
        wireframeRenderer: WireframeRenderer,
        stopScanCallback: @escaping () -> Void
    ) {
        self.viewModel          = viewModel
        self.wireframeRenderer  = wireframeRenderer
        self.stopScanCallback   = stopScanCallback
    }

    // MARK: - Mesh extraction

    /// Extracts vertex, face, and normal data from an ARMeshGeometry into a value-type MeshData.
    private func extractMeshData(from anchor: ARMeshAnchor) -> MeshData? {
        let geometry = anchor.geometry

        // --- Vertices ---
        let vertexBuffer = geometry.vertices
        guard vertexBuffer.componentsPerVector == 3 else { return nil }
        let vertexCount  = vertexBuffer.count
        var vertices     = [SIMD3<Float>]()
        vertices.reserveCapacity(vertexCount)

        vertexBuffer.buffer.contents().withMemoryRebound(to: SIMD3<Float>.self, capacity: vertexCount) { ptr in
            for i in 0 ..< vertexCount {
                vertices.append(ptr[i])
            }
        }

        // --- Normals ---
        let normalBuffer = geometry.normals
        let normalCount  = normalBuffer.count
        var normals      = [SIMD3<Float>]()
        normals.reserveCapacity(normalCount)

        normalBuffer.buffer.contents().withMemoryRebound(to: SIMD3<Float>.self, capacity: normalCount) { ptr in
            for i in 0 ..< normalCount {
                normals.append(ptr[i])
            }
        }

        // --- Faces (indices) ---
        let faceBuffer  = geometry.faces
        // Each face is a triangle: primitiveType .triangle guarantees 3 indices per face
        let indexCount  = faceBuffer.count * 3
        var faces       = [UInt32]()
        faces.reserveCapacity(indexCount)

        // ARMeshGeometry.faces uses UInt32 indices
        faceBuffer.buffer.contents().withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
            for i in 0 ..< indexCount {
                faces.append(ptr[i])
            }
        }

        return MeshData(
            vertices:  vertices,
            faces:     faces,
            normals:   normals,
            transform: anchor.transform
        )
    }

    // MARK: - Throttle helper

    private func shouldRebuild() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastRebuildDate) >= rebuildInterval else { return false }
        lastRebuildDate = now
        return true
    }

    // MARK: - Shared anchor handling

    private func handle(anchor: ARMeshAnchor, scene: SCNScene) {
        // All mesh work happens off the main thread (we are already on an ARKit callback thread)
        autoreleasepool {
            guard let meshData = extractMeshData(from: anchor) else { return }

            // ViewModel writes must happen on MainActor
            let callback = stopScanCallback
            let guards   = hardwareGuards
            Task { @MainActor [weak self, weak viewModel = self.viewModel] in
                guard let viewModel else { return }
                viewModel.meshData.append(meshData)

                // Check vertex cap after append
                let total = viewModel.meshData.reduce(0) { $0 + $1.vertices.count }
                guards?.checkVertexCap(totalVertices: total)
            }

            // Wireframe rebuild — respects 5fps throttle
            guard shouldRebuild() else { return }
            wireframeRenderer?.updateNode(for: anchor, in: scene)
        }
    }
}

// MARK: - ARSCNViewDelegate

extension MeshAnchorHandler: ARSCNViewDelegate {

    /// Called when a new anchor (e.g. ARMeshAnchor) is added to the scene.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor,
              let scene      = renderer.scene else { return }
        handle(anchor: meshAnchor, scene: scene)
    }

    /// Called when an existing anchor is updated (mesh refined by LiDAR).
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor,
              let scene      = renderer.scene else { return }
        handle(anchor: meshAnchor, scene: scene)
    }
}

// MARK: - ARSessionDelegate

extension MeshAnchorHandler: ARSessionDelegate {

    /// Forwards camera tracking state changes to HardwareGuards.
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        hardwareGuards?.handleTrackingState(camera.trackingState)
    }

    /// Checks ambient light intensity for low-light warnings.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let lightEstimate = frame.lightEstimate {
            hardwareGuards?.checkLightEstimate(lightEstimate.ambientIntensity)
        }
    }
}
