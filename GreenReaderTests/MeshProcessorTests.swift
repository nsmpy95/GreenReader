import XCTest
import simd
@testable import GreenReader

// MARK: - MeshProcessorTests
final class MeshProcessorTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a simple flat quad (two triangles) in the XZ plane with the given normals.
    private func makeMeshData(
        vertices: [SIMD3<Float>],
        normals:  [SIMD3<Float>],
        faces:    [UInt32]? = nil
    ) -> MeshData {
        let defaultFaces: [UInt32] = [0, 1, 2, 0, 2, 3]
        return MeshData(
            vertices:  vertices,
            faces:     faces ?? defaultFaces,
            normals:   normals,
            transform: matrix_identity_float4x4
        )
    }

    /// Returns a unit normal tilted `degrees` from the Y axis toward the X axis.
    private func tiltedNormal(degrees: Float) -> SIMD3<Float> {
        let rad = degrees * Float.pi / 180.0
        return simd_normalize(SIMD3<Float>(sin(rad), cos(rad), 0))
    }

    // MARK: - Test 1: Flat mesh → all .flat

    func testFlatMesh_allFlat() async throws {
        let flatNormal = SIMD3<Float>(0, 1, 0)
        let vertices: [SIMD3<Float>] = [
            SIMD3(-1,  0, -1),
            SIMD3( 1,  0, -1),
            SIMD3( 1,  0,  1),
            SIMD3(-1,  0,  1)
        ]
        let normals = [SIMD3<Float>](repeating: flatNormal, count: vertices.count)
        let mesh    = makeMeshData(vertices: vertices, normals: normals)

        let viewModel = ScanViewModel()
        viewModel.meshData = [mesh]
        viewModel.scanState = .processing

        let processor = MeshProcessor()
        await processor.process([mesh], viewModel: viewModel)

        XCTAssertFalse(viewModel.slopeData.isEmpty, "slopeData must not be empty")
        for point in viewModel.slopeData {
            XCTAssertEqual(
                point.category, .flat,
                "All vertices of a flat mesh should be .flat, got angle \(point.slopeAngle)°"
            )
        }
    }

    // MARK: - Test 2: 3° slope → all .moderate

    func test3DegreeSlope_allModerate() async throws {
        let slopedNormal = tiltedNormal(degrees: 3.0)
        let vertices: [SIMD3<Float>] = [
            SIMD3(-1,  0, -1),
            SIMD3( 1,  0, -1),
            SIMD3( 1,  0,  1),
            SIMD3(-1,  0,  1)
        ]
        let normals = [SIMD3<Float>](repeating: slopedNormal, count: vertices.count)
        let mesh    = makeMeshData(vertices: vertices, normals: normals)

        let viewModel = ScanViewModel()
        let processor = MeshProcessor()
        await processor.process([mesh], viewModel: viewModel)

        XCTAssertFalse(viewModel.slopeData.isEmpty)
        for point in viewModel.slopeData {
            XCTAssertEqual(
                point.category, .moderate,
                "3° normals should map to .moderate, got \(point.slopeAngle)°"
            )
        }
    }

    // MARK: - Test 3: Laplacian smoother reduces a spike

    func testLaplacianSmoother_reducesSpike() {
        // Flat grid in XZ plane with one spike vertex lifted high on Y
        var vertices: [SIMD3<Float>] = [
            SIMD3(-1, 0, -1),   // 0
            SIMD3( 0, 0, -1),   // 1
            SIMD3( 1, 0, -1),   // 2
            SIMD3(-1, 0,  0),   // 3
            SIMD3( 0, 5,  0),   // 4 ← spike
            SIMD3( 1, 0,  0),   // 5
            SIMD3(-1, 0,  1),   // 6
            SIMD3( 0, 0,  1),   // 7
            SIMD3( 1, 0,  1)    // 8
        ]
        let spikeIndex = 4
        let originalSpikeY = vertices[spikeIndex].y

        // Triangulate the 3×3 grid (8 quads → 8 pairs of triangles, but we
        // only need enough connectivity to give vertex 4 neighbours)
        let faces: [UInt32] = [
            0,1,4,  0,4,3,
            1,2,5,  1,5,4,
            3,4,7,  3,7,6,
            4,5,8,  4,8,7
        ]

        LaplacianSmoother.smooth(vertices: &vertices, faces: faces, iterations: 3, lambda: 0.5)

        let smoothedSpikeY = vertices[spikeIndex].y
        XCTAssertLessThan(
            smoothedSpikeY, originalSpikeY,
            "Spike Y should decrease after smoothing (was \(originalSpikeY), now \(smoothedSpikeY))"
        )
    }

    // MARK: - Test 4: Slope angle precision

    func testSlopeAnglePrecision() {
        // A normal tilted exactly 2.5° from vertical
        let expectedAngle: Float = 2.5
        let testNormal = tiltedNormal(degrees: expectedAngle)

        let results = SlopeAnalyzer.analyse(
            vertices: [SIMD3<Float>(0, 0, 0)],
            normals:  [testNormal]
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(
            results[0].slopeAngle, expectedAngle,
            accuracy: 0.01,
            "Slope angle should match expected value within 0.01°"
        )
    }

    // MARK: - Test 5: Performance with 50 k vertices

    func testPerformance50kVertices() async {
        let count = 50_000
        var vertices = [SIMD3<Float>](repeating: .zero, count: count)
        var normals  = [SIMD3<Float>](repeating: SIMD3<Float>(0, 1, 0), count: count)
        var faces    = [UInt32]()
        faces.reserveCapacity((count - 2) * 3)

        // Lay out vertices in a flat grid
        let side = Int(sqrt(Double(count)))
        for i in 0 ..< count {
            let row = i / side
            let col = i % side
            vertices[i] = SIMD3<Float>(Float(col), 0, Float(row))
        }

        // Simple strip triangulation
        for row in 0 ..< (side - 1) {
            for col in 0 ..< (side - 1) {
                let tl = UInt32(row * side + col)
                let tr = tl + 1
                let bl = UInt32((row + 1) * side + col)
                let br = bl + 1
                faces += [tl, tr, bl, tr, br, bl]
            }
        }

        let mesh = MeshData(
            vertices:  vertices,
            faces:     faces,
            normals:   normals,
            transform: matrix_identity_float4x4
        )

        let viewModel = ScanViewModel()
        let processor = MeshProcessor()

        let start = Date()
        await processor.process([mesh], viewModel: viewModel)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 2.0, "50 k vertices should process in under 2 seconds (took \(String(format: "%.2f", elapsed))s)")
        XCTAssertEqual(viewModel.slopeData.count, count)
    }
}
