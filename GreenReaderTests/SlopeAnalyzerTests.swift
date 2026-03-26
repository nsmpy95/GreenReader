import XCTest
import simd
@testable import GreenReader

// MARK: - SlopeAnalyzerTests
final class SlopeAnalyzerTests: XCTestCase {

    // MARK: - Test 1: Flat normal → 0° slope, .flat category

    func testFlatNormal_zeroSlope() {
        let flatNormal = SIMD3<Float>(0, 1, 0)
        let results = SlopeAnalyzer.analyse(
            vertices: [SIMD3<Float>(0, 0, 0)],
            normals:  [flatNormal]
        )

        XCTAssertEqual(results.count, 1)
        let point = results[0]
        XCTAssertEqual(point.slopeAngle, 0.0, accuracy: 0.001, "Upward normal should yield 0° slope")
        XCTAssertEqual(point.category, .flat, "0° should be .flat")
    }

    // MARK: - Test 2: Horizontal (vertical wall) normal → 90°, .severe

    func testVerticalNormal_90Slope() {
        let horizontalNormal = SIMD3<Float>(1, 0, 0)
        let results = SlopeAnalyzer.analyse(
            vertices: [SIMD3<Float>(0, 0, 0)],
            normals:  [horizontalNormal]
        )

        XCTAssertEqual(results.count, 1)
        let point = results[0]
        XCTAssertEqual(point.slopeAngle, 90.0, accuracy: 0.001, "Horizontal normal should yield 90° slope")
        XCTAssertEqual(point.category, .severe, "90° should be .severe")
    }

    // MARK: - Test 3: Color mapping matches design tokens

    func testColorMapping() {
        // Craft normals that land precisely in each category
        let normals: [(SIMD3<Float>, SlopeCategory, SIMD4<Float>)] = [
            // flat: ~0.5°
            (tiltedNormal(degrees: 0.5), .flat,     SIMD4<Float>(0.298, 0.686, 0.314, 1.0)),
            // subtle: ~1.5°
            (tiltedNormal(degrees: 1.5), .subtle,   SIMD4<Float>(1.000, 0.922, 0.231, 1.0)),
            // moderate: ~3.0°
            (tiltedNormal(degrees: 3.0), .moderate, SIMD4<Float>(1.000, 0.596, 0.000, 1.0)),
            // severe: ~10°
            (tiltedNormal(degrees: 10.0), .severe,  SIMD4<Float>(0.957, 0.263, 0.212, 1.0))
        ]

        for (normal, expectedCategory, expectedColor) in normals {
            let results = SlopeAnalyzer.analyse(
                vertices: [SIMD3<Float>(0, 0, 0)],
                normals:  [normal]
            )
            XCTAssertEqual(results.count, 1)
            let point = results[0]
            XCTAssertEqual(point.category, expectedCategory, "Category mismatch for angle \(point.slopeAngle)°")

            XCTAssertEqual(point.color.x, expectedColor.x, accuracy: 0.001, "R channel mismatch for \(expectedCategory)")
            XCTAssertEqual(point.color.y, expectedColor.y, accuracy: 0.001, "G channel mismatch for \(expectedCategory)")
            XCTAssertEqual(point.color.z, expectedColor.z, accuracy: 0.001, "B channel mismatch for \(expectedCategory)")
            XCTAssertEqual(point.color.w, 1.0,             accuracy: 0.001, "Alpha should always be 1.0")
        }
    }

    // MARK: - Test 4: slopeDirection is the XZ projection of the normal

    func testSlopeDirection_correctProjection() {
        // Normal with known X and Z components
        let normal = simd_normalize(SIMD3<Float>(3, 4, 5))
        let results = SlopeAnalyzer.analyse(
            vertices: [SIMD3<Float>(0, 0, 0)],
            normals:  [normal]
        )

        XCTAssertEqual(results.count, 1)
        let dir = results[0].slopeDirection

        // Expected: XZ projection of `normal`, normalised
        let rawDir = SIMD2<Float>(normal.x, normal.z)
        let expectedDir = rawDir / simd_length(rawDir)

        XCTAssertEqual(dir.x, expectedDir.x, accuracy: 0.001, "slopeDirection.x should match XZ projection")
        XCTAssertEqual(dir.y, expectedDir.y, accuracy: 0.001, "slopeDirection.y should match XZ projection")

        // Result should be unit length
        let len = simd_length(dir)
        XCTAssertEqual(len, 1.0, accuracy: 0.001, "slopeDirection should be unit length")
    }

    // MARK: - Private helpers

    /// Returns a unit normal tilted `degrees` from the Y axis toward the X axis.
    private func tiltedNormal(degrees: Float) -> SIMD3<Float> {
        let rad = degrees * Float.pi / 180.0
        return simd_normalize(SIMD3<Float>(sin(rad), cos(rad), 0))
    }
}
