import simd

// MARK: - MeshData
// Raw LiDAR mesh from a single ARMeshAnchor.
// Produced by M2, consumed by M3.
struct MeshData: Sendable {
    let vertices:  [SIMD3<Float>]
    let faces:     [UInt32]
    let normals:   [SIMD3<Float>]
    let transform: simd_float4x4
}
