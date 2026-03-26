# GreenReader — Claude Code Project

## What this project is
An iOS app that uses the iPhone LiDAR sensor to scan a golf green and display a
color-coded slope map as a transparent AR overlay. Target device: iPhone 15 Pro.
Minimum deployment: iOS 17.0.

## Architecture
MVVM with `@Observable` (iOS 17). No external dependencies — native Apple
frameworks only: ARKit 6, SceneKit, SwiftUI, Accelerate.

The single source of truth is `ScanViewModel`. All modules read from and write
back to it. Never bypass the ViewModel to talk directly between modules.

```
ScanViewModel.scanState: .idle → .scanning → .processing → .results → .idle
```

## Module map
| Folder | Responsibility | Agent |
|---|---|---|
| M1_Foundation | LiDAR gate, camera preview, app shell | @agent-foundation |
| M2_ScanningEngine | ARKit session, mesh capture, thermal/memory guards | @agent-scanner |
| M3_SlopeCalculation | Mesh merge, Laplacian smooth, normal → slope math | @agent-math |
| M4_VisualizationUI | SCNGeometry overlay, SwiftUI state UI, animations | @agent-ui |
| M5_LaunchPolish | Launch screen, onboarding, settings, edge-case UX | @agent-polish |
| Shared/Models | Data structs shared across modules | any agent |
| Shared/Utilities | Pure functions, extensions, constants | any agent |

## Hard constraints — read before writing any code
- LiDAR effective range on grass: **0.2–5 metres**. UX must guide the user to
  walk the green, not scan from distance.
- Mesh update callbacks fire 10+ times/sec — throttle SCNGeometry rebuilds to
  ≤5 fps.
- Cap total mesh vertices at **100 000**. Auto-stop and notify if exceeded.
- `writesToDepthBuffer = false` on the slope overlay material. Non-negotiable —
  prevents z-fighting with AR planes.
- All processing off the main thread. Use `async/await` with a background actor.
- Release raw `MeshData` array after processing. Keep only the processed
  `SCNGeometry`.

## Code style
- Swift 5.9, SwiftUI-first, UIViewRepresentable only for ARSCNView.
- `@Observable` for ViewModels (no ObservableObject).
- Explicit `sendable` conformance on any type crossing actor boundaries.
- No force-unwraps. Guard-let or `if let`, never `!`.
- Every public function needs a one-line doc comment.

## Design tokens
```swift
// Use these constants from DesignTokens.swift — do not hardcode colours
Color.greenAccent   // #00C853
Color.darkBg        // #1A1A1A
// Slope classification colours
Color.slopeFlat     // #4CAF50
Color.slopeSubtle   // #FFEB3B
Color.slopeModerate // #FF9800
Color.slopeSevere   // #F44336
```

## Running the project
This is a native Xcode project. Claude Code cannot run it — it can only write
and validate Swift source files. To test, open `GreenReader.xcodeproj` in
Xcode and run on a physical LiDAR device.

## Testing
Unit tests live in `GreenReaderTests/`. Math-heavy logic in M3 must have
corresponding tests. UI and ARKit code cannot be unit tested — test on device.
