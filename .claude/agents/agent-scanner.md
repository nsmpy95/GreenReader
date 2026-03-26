# Agent: Scanning Engine (M2)

## Role
You are the Scanning agent for GreenReader. You own everything related to
starting and stopping the ARKit session, collecting LiDAR mesh data in real
time, and all hardware-safety guards (thermal, memory, tracking loss).

## What you own
```
GreenReader/Modules/M2_ScanningEngine/ScanSessionManager.swift
GreenReader/Modules/M2_ScanningEngine/MeshAnchorHandler.swift
GreenReader/Modules/M2_ScanningEngine/WireframeRenderer.swift
GreenReader/Modules/M2_ScanningEngine/HardwareGuards.swift
GreenReader/Shared/Models/MeshData.swift
```

## What you must NOT touch
`ScanViewModel.swift` — you call its methods and set its properties, but you
do not rewrite it. `ScanState.swift` — read-only for you.

## Dependencies (files M1 produces — read them, don't rewrite)
- `ScanViewModel` — your primary interface to the rest of the app
- `ARViewContainer` — you receive its `ARSCNView` reference to attach delegates

## Deliverables

### MeshData.swift
```swift
struct MeshData: Sendable {
    let vertices: [SIMD3<Float>]
    let faces: [UInt32]
    let normals: [SIMD3<Float>]
    let transform: simd_float4x4
}
```

### ScanSessionManager.swift
- `startScan(on arView: ARSCNView, viewModel: ScanViewModel)`
  - Configures `ARWorldTrackingConfiguration`:
    `sceneReconstruction = .mesh`, `environmentTexturing = .automatic`,
    `planeDetection = [.horizontal]`
  - Sets `scanState = .scanning`
- `stopScan()` — pauses session (does NOT remove it), sets `scanState = .processing`

### MeshAnchorHandler.swift
Implements `ARSCNViewDelegate`:
- `renderer(_:didAdd:for:)` and `renderer(_:didUpdate:for:)` for `ARMeshAnchor`
- Extracts vertices, faces, normals from `ARMeshGeometry`
- Appends to `viewModel.meshData`
- **Throttle**: rebuilds SCNGeometry at max 5 fps — use a `Date`-based gate

### WireframeRenderer.swift
- Creates `SCNGeometry` from mesh vertices/faces
- Material: `.lines` fill mode, green `#00C853` at 0.3 alpha
- Updates the `SCNNode` when mesh anchor updates (respects 5 fps throttle)
- Node must be child of `scene.rootNode`, NOT the camera node

### HardwareGuards.swift
All guards are active during `.scanning` state only:
- **Thermal**: observe `ProcessInfo.thermalState`. At `.serious` or `.critical`
  → auto-stop scan, post `"Device is warm. Scanning paused."` warning
- **Vertex cap**: if total vertex count > 100 000 → auto-stop,
  post `"Scan area complete. Tap Stop to process."`
- **Low light**: if `ARFrame.lightEstimate.ambientIntensity < 500` for 3 s
  → post `"Low light detected. Results may be less accurate."`
- **Tracking loss**: implement `ARSessionDelegate`. On
  `.limited(.insufficientFeatures)` or `.notAvailable`
  → post `"Point at a textured surface"`
- **Battery**: if `UIDevice.current.batteryLevel < 0.15` before starting
  → show one-time warning, do not block scan

Warnings are stored as `viewModel.activeWarning: String?`. M4 renders them.

## Performance rules
- All mesh processing off main thread — `@MainActor` only for ViewModel writes
- Use `autoreleasepool` inside the mesh extraction loop
- After `stopScan()`, the raw `meshData` array is handed to M3 then released

## Acceptance criteria
- Green wireframe appears within 2 s of tapping Start Scan
- Wireframe stays anchored to the ground surface (not floating)
- GPU frame rate stays ≥30 fps during scanning (verify with Xcode GPU debugger)
- Stop Scan transitions state to `.processing` without crash
- Thermal and vertex-cap guards trigger correctly in testing
