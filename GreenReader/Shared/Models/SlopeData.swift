import simd

// MARK: - SlopeCategory
enum SlopeCategory: Sendable {
    case flat        // 0–1°
    case subtle      // 1–2°
    case moderate    // 2–4°
    case severe      // 4°+
}

// MARK: - SlopeData
// Processed per-vertex slope result.
// Produced by M3, consumed by M4.
struct SlopeData: Sendable {
    let position:       SIMD3<Float>
    let slopeAngle:     Float           // degrees
    let slopeDirection: SIMD2<Float>    // XZ projection (fall line)
    let color:          SIMD4<Float>    // RGBA for SceneKit vertex colour
    let category:       SlopeCategory
}
