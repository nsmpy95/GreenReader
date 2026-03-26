import ARKit
import SceneKit
import UIKit

// MARK: - WireframeRenderer
// Maintains a per-anchor dictionary of SCNNodes and updates their geometry
// to show a live wireframe overlay of the captured LiDAR mesh.
final class WireframeRenderer {

    // MARK: - State

    /// One SCNNode per ARMeshAnchor identifier.
    private var anchorNodes: [UUID: SCNNode] = [:]

    // MARK: - Material factory

    private func makeMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.fillMode        = .lines
        // #00C853 (Color.greenAccent) at 30% opacity
        material.diffuse.contents = UIColor(red: 0, green: 0.784, blue: 0.325, alpha: 0.3)
        material.isDoubleSided   = true
        material.lightingModel   = .constant   // unaffected by scene lighting
        return material
    }

    // MARK: - SCNGeometry builder

    /// Converts raw vertex and face arrays from an ARMeshAnchor into a SceneKit geometry.
    private func buildGeometry(from anchor: ARMeshAnchor) -> SCNGeometry? {
        let geometry  = anchor.geometry
        let vertices  = geometry.vertices
        let faces     = geometry.faces

        let vertexCount = vertices.count
        guard vertexCount > 0 else { return nil }

        // --- Vertex source ---
        // Stride is always 12 bytes (3 × Float32) for SIMD3<Float>
        let vertexStride = MemoryLayout<SIMD3<Float>>.stride
        let vertexData   = Data(
            bytes:  vertices.buffer.contents(),
            count:  vertexCount * vertexStride
        )
        let vertexSource = SCNGeometrySource(
            data:               vertexData,
            semantic:           .vertex,
            vectorCount:        vertexCount,
            usesFloatComponents: true,
            dataOffset:         0,
            dataStride:         vertexStride
        )

        // --- Index element (triangles) ---
        let indexCount = faces.count * 3
        let indexData  = Data(
            bytes:  faces.buffer.contents(),
            count:  indexCount * MemoryLayout<UInt32>.size
        )
        let element = SCNGeometryElement(
            data:           indexData,
            primitiveType:  .triangles,
            primitiveCount: faces.count,
            bytesPerIndex:  MemoryLayout<UInt32>.size
        )

        let scnGeometry = SCNGeometry(sources: [vertexSource], elements: [element])
        scnGeometry.materials = [makeMaterial()]
        return scnGeometry
    }

    // MARK: - Public API

    /// Creates or updates the SCNNode for the given ARMeshAnchor in the supplied scene.
    func updateNode(for anchor: ARMeshAnchor, in scene: SCNScene) {
        guard let newGeometry = buildGeometry(from: anchor) else { return }

        let anchorID = anchor.identifier

        if let existing = anchorNodes[anchorID] {
            // Update geometry in place — avoids re-parenting
            existing.geometry  = newGeometry
            existing.simdTransform = anchor.transform
        } else {
            // Create and parent to scene root (NOT the camera node)
            let node           = SCNNode(geometry: newGeometry)
            node.simdTransform = anchor.transform
            scene.rootNode.addChildNode(node)
            anchorNodes[anchorID] = node
        }
    }

    /// Removes all wireframe nodes from the scene and clears internal state.
    func removeAllNodes(from scene: SCNScene) {
        for node in anchorNodes.values {
            node.removeFromParentNode()
        }
        anchorNodes.removeAll()
    }
}
