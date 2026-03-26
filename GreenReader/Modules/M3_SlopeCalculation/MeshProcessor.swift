import simd
import Observation

// MARK: - MeshProcessor
/// Background actor that drives the M3 pipeline: merge → smooth → analyse → publish.
actor MeshProcessor {

    // MARK: - Public API

    /// Entry point: merges, smooths, analyses mesh data and updates the ViewModel.
    func process(_ meshData: [MeshData], viewModel: ScanViewModel) async {
        // --- 1. Merge all anchors into world-space buffers ---
        var allVertices = [SIMD3<Float>]()
        var allNormals  = [SIMD3<Float>]()
        var allFaces    = [UInt32]()

        for mesh in meshData {
            let offset = UInt32(allVertices.count)
            let transform = mesh.transform

            // Extract the upper-left 3×3 of the 4×4 for normal transformation
            let normalMatrix = simd_float3x3(
                SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
                SIMD3<Float>(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
                SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
            )

            for vertex in mesh.vertices {
                let v4 = transform * SIMD4<Float>(vertex, 1)
                allVertices.append(SIMD3<Float>(v4.x, v4.y, v4.z))
            }

            for normal in mesh.normals {
                let n = normalMatrix * normal
                let len = simd_length(n)
                allNormals.append(len > 0 ? n / len : n)
            }

            // Offset face indices so they point into the combined vertex array
            for index in mesh.faces {
                allFaces.append(index + offset)
            }
        }

        guard !allVertices.isEmpty else { return }

        // --- 2. Smooth ---
        LaplacianSmoother.smooth(
            vertices: &allVertices,
            faces: allFaces,
            iterations: 3,
            lambda: 0.5
        )

        // --- 3. Analyse ---
        let result = SlopeAnalyzer.analyse(vertices: allVertices, normals: allNormals)

        // --- 4. Compute distribution for logging ---
        logDistribution(result)

        // --- 5. Publish to ViewModel on MainActor ---
        let maxSlope = result.map(\.slopeAngle).max() ?? 0
        let avgSlope = result.isEmpty
            ? 0
            : result.map(\.slopeAngle).reduce(0, +) / Float(result.count)

        await MainActor.run {
            viewModel.slopeData = result
            viewModel.maxSlope  = maxSlope
            viewModel.avgSlope  = avgSlope
            viewModel.scanState = .results
            viewModel.clearRawMeshData()   // release raw MeshData
        }
    }

    // MARK: - Private helpers

    /// Logs the percentage breakdown by SlopeCategory.
    private func logDistribution(_ data: [SlopeData]) {
        guard !data.isEmpty else { return }

        var flat = 0, subtle = 0, moderate = 0, severe = 0

        for point in data {
            switch point.category {
            case .flat:     flat     += 1
            case .subtle:   subtle   += 1
            case .moderate: moderate += 1
            case .severe:   severe   += 1
            }
        }

        let total  = Float(data.count)
        let pct    = { (n: Int) in String(format: "%.1f", Float(n) / total * 100) }

        print("Slope distribution: flat=\(pct(flat))%, subtle=\(pct(subtle))%, moderate=\(pct(moderate))%, severe=\(pct(severe))%")
    }
}
