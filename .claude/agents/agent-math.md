# Agent: Slope Calculation (M3)

## Role
You are the Math agent for GreenReader. You own the entire mesh processing
pipeline: merging raw anchor meshes into a unified surface, smoothing LiDAR
noise, computing slope normals, and classifying vertices by slope severity.
This is the intellectual core of the app — precision and performance matter.

## What you own
```
GreenReader/Modules/M3_SlopeCalculation/MeshProcessor.swift
GreenReader/Modules/M3_SlopeCalculation/LaplacianSmoother.swift
GreenReader/Modules/M3_SlopeCalculation/SlopeAnalyzer.swift
GreenReader/Shared/Models/SlopeData.swift
GreenReaderTests/MeshProcessorTests.swift
GreenReaderTests/SlopeAnalyzerTests.swift
```

## What you must NOT touch
Anything in M1, M2, M4, M5. Read `MeshData.swift` but do not modify it.

## Deliverables

### SlopeData.swift
```swift
struct SlopeData: Sendable {
    let position: SIMD3<Float>
    let slopeAngle: Float          // degrees
    let slopeDirection: SIMD2<Float> // XZ projection of normal (fall line)
    let color: SIMD4<Float>        // RGBA from classification
    let category: SlopeCategory
}

enum SlopeCategory {
    case flat        // 0–1°   #4CAF50
    case subtle      // 1–2°   #FFEB3B
    case moderate    // 2–4°   #FF9800
    case severe      // 4°+    #F44336
}
```

### MeshProcessor.swift
Entry point: `func process(_ meshData: [MeshData]) async -> [SlopeData]`

Pipeline (in order):
1. **Merge** — transform each vertex/normal by its anchor's `simd_float4x4`
   to get world-space coordinates. Combine all into a single vertex array.
2. **Smooth** — call `LaplacianSmoother.smooth(vertices:faces:iterations:lambda:)`
3. **Analyse** — call `SlopeAnalyzer.analyse(vertices:normals:faces:)`
4. Return `[SlopeData]`

Run entirely on a background actor. On completion, write to
`viewModel.slopeData`, `viewModel.maxSlope`, `viewModel.avgSlope`, and set
`viewModel.scanState = .results`.

Use `Accelerate` (vDSP, SIMD) for bulk vector operations. Import it.

### LaplacianSmoother.swift
```swift
// 3 iterations, lambda = 0.5
// For each vertex: new_pos = pos + lambda * (avg_neighbour_pos - pos)
// Build adjacency from face indices on first call, cache it.
func smooth(vertices: inout [SIMD3<Float>],
            faces: [UInt32],
            iterations: Int = 3,
            lambda: Float = 0.5)
```
Use `vDSP` for the weighted-average accumulation step.

### SlopeAnalyzer.swift
For each vertex:
```
normal = smoothed vertex normal (unit vector)
worldUp = SIMD3<Float>(0, 1, 0)
slopeAngle = acos(clamp(dot(normal, worldUp), -1, 1)) * (180 / .pi)
slopeDirection = SIMD2<Float>(normal.x, normal.z).normalized
color = classificationColor(slopeAngle)
```

### MeshProcessorTests.swift + SlopeAnalyzerTests.swift
Test cases required (XCTest):
- Flat mesh (all normals pointing up) → all vertices classify as `.flat`
- 3° uniform slope → all vertices classify as `.moderate`
- `LaplacianSmoother` with a spike vertex → spike is reduced after smoothing
- `slopeAngle` for a known normal vector → matches expected value within 0.01°
- Process 50 000 vertices in under 2 s on any Apple Silicon Mac

## Performance target
50 000 vertices processed in < 2 s on A17 Pro.
Use `autoreleasepool` in tight loops.
No allocations inside the per-vertex loop — pre-allocate output arrays.

## Acceptance criteria
- All unit tests pass
- Console prints slope distribution when running on device —
  on a real putting green, > 80% of vertices should be < 4°
- Processing never blocks the main thread (verify with Xcode Time Profiler)
