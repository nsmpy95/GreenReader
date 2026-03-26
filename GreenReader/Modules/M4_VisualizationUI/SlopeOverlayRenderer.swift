import SceneKit
import simd

// MARK: - SlopeOverlayRenderer
// Builds and removes the SCNNode slope colour overlay from processed SlopeData.
// All geometry is constructed off-screen; fade animations run on the SceneKit
// render thread via SCNAction.
final class SlopeOverlayRenderer {

    // Tag used to find and remove the overlay node.
    private let overlayNodeName = "GreenReader.SlopeOverlay"

    // MARK: - Build

    /// Constructs a coloured SCNGeometry from slope data and adds it to the scene with a fade-in.
    func buildOverlay(from slopeData: [SlopeData], in scene: SCNScene) -> SCNNode {
        let node = SCNNode(geometry: makeGeometry(from: slopeData))
        node.name = overlayNodeName

        // Start fully transparent; animate to target opacity.
        node.opacity = 0
        let fadeIn = SCNAction.fadeOpacity(to: 0.65, duration: 0.5)
        node.runAction(fadeIn)

        scene.rootNode.addChildNode(node)
        return node
    }

    /// Fades out and removes the overlay node from the scene.
    func removeOverlay(from scene: SCNScene) {
        guard let node = scene.rootNode.childNode(withName: overlayNodeName,
                                                   recursively: false) else { return }
        let fadeOut = SCNAction.fadeOpacity(to: 0, duration: 0.3)
        let remove  = SCNAction.removeFromParentNode()
        node.runAction(SCNAction.sequence([fadeOut, remove]))
    }

    // MARK: - Geometry construction

    private func makeGeometry(from slopeData: [SlopeData]) -> SCNGeometry {
        // --- Positions ---
        let positions: [SIMD3<Float>] = slopeData.map { $0.position }
        let positionSource = positions.withUnsafeBytes { ptr -> SCNGeometrySource in
            SCNGeometrySource(
                data: Data(ptr),
                semantic: .vertex,
                vectorCount: positions.count,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )
        }

        // --- Normals (point straight up — slope colour encodes the angle) ---
        let up = SIMD3<Float>(0, 1, 0)
        let normals = [SIMD3<Float>](repeating: up, count: slopeData.count)
        let normalSource = normals.withUnsafeBytes { ptr -> SCNGeometrySource in
            SCNGeometrySource(
                data: Data(ptr),
                semantic: .normal,
                vectorCount: normals.count,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )
        }

        // --- Per-vertex RGBA colours ---
        let colors: [SIMD4<Float>] = slopeData.map { $0.color }
        let colorSource = colors.withUnsafeBytes { ptr -> SCNGeometrySource in
            SCNGeometrySource(
                data: Data(ptr),
                semantic: .color,
                vectorCount: colors.count,
                usesFloatComponents: true,
                componentsPerVector: 4,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD4<Float>>.stride
            )
        }

        // --- Triangle indices ---
        // Build a mesh of triangles from consecutive vertex triples.
        // Vertices are assumed to arrive in triangle-list order from M3.
        let vertexCount = slopeData.count
        // Clamp to the nearest complete triangle.
        let triangleCount = (vertexCount / 3)
        var indices = [Int32]()
        indices.reserveCapacity(triangleCount * 3)
        for i in 0 ..< triangleCount * 3 {
            indices.append(Int32(i))
        }

        let element = indices.withUnsafeBytes { ptr -> SCNGeometryElement in
            SCNGeometryElement(
                data: Data(ptr),
                primitiveType: .triangles,
                primitiveCount: triangleCount,
                bytesPerIndex: MemoryLayout<Int32>.size
            )
        }

        // --- Geometry ---
        let geometry = SCNGeometry(sources: [positionSource, normalSource, colorSource],
                                   elements: [element])

        // --- Material ---
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.isDoubleSided = true
        material.writesToDepthBuffer = false   // prevents z-fighting with AR planes
        material.transparency = 0.65
        // Signal SceneKit to use vertex colours as the diffuse input.
        material.diffuse.contents = NSNull()

        geometry.materials = [material]
        return geometry
    }
}
