import simd
import Accelerate

// MARK: - SlopeAnalyzer
/// Converts per-vertex normals into SlopeData values (angle, direction, category, colour).
struct SlopeAnalyzer {

    // MARK: - Public API

    /// Analyses per-vertex slope angles from normals. Returns SlopeData array.
    static func analyse(vertices: [SIMD3<Float>], normals: [SIMD3<Float>]) -> [SlopeData] {
        let count = min(vertices.count, normals.count)
        guard count > 0 else { return [] }

        // Pre-allocate output — no allocation inside the loop
        var results = [SlopeData](repeating: SlopeData(
            position: .zero,
            slopeAngle: 0,
            slopeDirection: .zero,
            color: SIMD4<Float>(0.298, 0.686, 0.314, 1.0),
            category: .flat
        ), count: count)

        let worldUp = SIMD3<Float>(0, 1, 0)
        let radiansToDegreees: Float = 180.0 / Float.pi

        for i in 0 ..< count {
            let normal = normals[i]

            // Clamp dot product to [-1, 1] to guard acos domain
            let dot = simd_clamp(simd_dot(normal, worldUp), -1.0, 1.0)
            let slopeAngle = acos(dot) * radiansToDegreees

            // XZ projection (fall line)
            let rawDir = SIMD2<Float>(normal.x, normal.z)
            let dirLen = simd_length(rawDir)
            let slopeDirection = dirLen > 0 ? rawDir / dirLen : rawDir

            let category = classify(slopeAngle)
            let color    = colorForCategory(category)

            results[i] = SlopeData(
                position:       vertices[i],
                slopeAngle:     slopeAngle,
                slopeDirection: slopeDirection,
                color:          color,
                category:       category
            )
        }

        return results
    }

    // MARK: - Private helpers

    /// Maps a slope angle in degrees to a SlopeCategory.
    private static func classify(_ angleDegrees: Float) -> SlopeCategory {
        switch angleDegrees {
        case ..<1.0:  return .flat
        case ..<2.0:  return .subtle
        case ..<4.0:  return .moderate
        default:      return .severe
        }
    }

    /// Returns the RGBA colour (as SIMD4<Float>) for a given SlopeCategory.
    private static func colorForCategory(_ category: SlopeCategory) -> SIMD4<Float> {
        switch category {
        case .flat:     return SIMD4<Float>(0.298, 0.686, 0.314, 1.0)   // #4CAF50
        case .subtle:   return SIMD4<Float>(1.000, 0.922, 0.231, 1.0)   // #FFEB3B
        case .moderate: return SIMD4<Float>(1.000, 0.596, 0.000, 1.0)   // #FF9800
        case .severe:   return SIMD4<Float>(0.957, 0.263, 0.212, 1.0)   // #F44336
        }
    }
}
