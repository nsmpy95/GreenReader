import simd
import Accelerate

// MARK: - LaplacianSmoother
/// Smooths a mesh by iteratively moving each vertex toward the centroid of its neighbours.
struct LaplacianSmoother {

    // MARK: - Public API

    /// Smooths mesh vertices using Laplacian filter. Builds adjacency from faces on first call.
    static func smooth(
        vertices: inout [SIMD3<Float>],
        faces: [UInt32],
        iterations: Int = 3,
        lambda: Float = 0.5
    ) {
        let vertexCount = vertices.count
        guard vertexCount > 0, faces.count >= 3 else { return }

        // Build adjacency list once — Set per vertex to avoid duplicates
        var adjacency = buildAdjacency(vertexCount: vertexCount, faces: faces)

        // Pre-allocate a scratch buffer for updated positions — no alloc inside loop
        var updated = [SIMD3<Float>](repeating: .zero, count: vertexCount)

        for _ in 0 ..< iterations {
            autoreleasepool {
                for i in 0 ..< vertexCount {
                    let neighbors = adjacency[i]
                    guard !neighbors.isEmpty else {
                        updated[i] = vertices[i]
                        return
                    }

                    // Accumulate neighbour positions using vDSP for x, y, z channels
                    var sumX: Float = 0
                    var sumY: Float = 0
                    var sumZ: Float = 0
                    let n = neighbors.count

                    // Gather neighbour components into contiguous arrays for vDSP
                    var nx = [Float](repeating: 0, count: n)
                    var ny = [Float](repeating: 0, count: n)
                    var nz = [Float](repeating: 0, count: n)

                    for (j, idx) in neighbors.enumerated() {
                        nx[j] = vertices[idx].x
                        ny[j] = vertices[idx].y
                        nz[j] = vertices[idx].z
                    }

                    // vDSP mean for each component
                    vDSP_meanv(nx, 1, &sumX, vDSP_Length(n))
                    vDSP_meanv(ny, 1, &sumY, vDSP_Length(n))
                    vDSP_meanv(nz, 1, &sumZ, vDSP_Length(n))

                    let avgNeighbour = SIMD3<Float>(sumX, sumY, sumZ)
                    let current      = vertices[i]
                    // new_pos = pos + lambda * (avg_neighbour - pos)
                    updated[i] = current + lambda * (avgNeighbour - current)
                }

                // Swap updated into vertices
                vertices = updated
            }
        }

        // Suppress unused-variable warning — adjacency used only inside loop
        _ = adjacency
    }

    // MARK: - Private helpers

    /// Builds a per-vertex neighbour list from the flat triangle-index array.
    private static func buildAdjacency(
        vertexCount: Int,
        faces: [UInt32]
    ) -> [[Int]] {
        var adjacency = [[Int]](repeating: [], count: vertexCount)

        // Use a Set per vertex temporarily to collect unique neighbours,
        // then flatten to Array to avoid repeated-contains checks later.
        var sets = [Set<Int>](repeating: Set<Int>(), count: vertexCount)

        let faceCount = faces.count / 3
        for f in 0 ..< faceCount {
            let base = f * 3
            let i0 = Int(faces[base])
            let i1 = Int(faces[base + 1])
            let i2 = Int(faces[base + 2])

            guard i0 < vertexCount, i1 < vertexCount, i2 < vertexCount else { continue }

            sets[i0].insert(i1); sets[i0].insert(i2)
            sets[i1].insert(i0); sets[i1].insert(i2)
            sets[i2].insert(i0); sets[i2].insert(i1)
        }

        for i in 0 ..< vertexCount {
            adjacency[i] = Array(sets[i])
        }

        return adjacency
    }
}
