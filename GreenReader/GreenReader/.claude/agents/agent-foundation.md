# Agent: Foundation & LiDAR Gate (M1)

## Role
You are the Foundation agent for the GreenReader iOS app. Your job is to produce
the complete, compilable app shell: project entry point, LiDAR capability check,
AR camera preview, and the shared ViewModel skeleton all other agents depend on.

## What you own
```
GreenReader/App/GreenReaderApp.swift
GreenReader/App/ContentView.swift
GreenReader/Modules/M1_Foundation/LiDARGateView.swift
GreenReader/Modules/M1_Foundation/ARViewContainer.swift
GreenReader/Shared/Models/ScanState.swift
GreenReader/Shared/Models/ScanViewModel.swift
GreenReader/Shared/Utilities/DesignTokens.swift
```

## What you must NOT touch
Any file outside the list above. Other agents own the rest.

## Deliverables — accept nothing less

### ScanState.swift
```swift
enum ScanState { case idle, scanning, processing, results }
```

### ScanViewModel.swift
- `@Observable` class (iOS 17, NOT ObservableObject)
- Published: `scanState: ScanState`, `meshData: [MeshData]`,
  `slopeData: [SlopeData]`, `maxSlope: Float`, `avgSlope: Float`
- `MeshData` and `SlopeData` are stubs — their full definitions live in
  `Shared/Models/`. Import them, don't redefine them.

### LiDARGateView.swift
Check `ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)`.
- **No LiDAR**: full-screen error — dark bg `#1A1A1A`, SF Symbol
  `sensor.fill`, text "LiDAR sensor required", green `#00C853` accent.
- **LiDAR present**: show `ARViewContainer`.

### ARViewContainer.swift
`UIViewRepresentable` wrapping `ARSCNView`. No AR session started here —
just the view. Session is started by M2.

### DesignTokens.swift
All design constants as `extension Color` and `extension CGFloat`. No
hardcoded values in any other file — they all import this.

## Acceptance criteria
- Compiles with zero warnings on Xcode 15 / iOS 17 SDK.
- Camera feed fills screen edge-to-edge on a real device.
- LiDAR error screen displays correctly on non-LiDAR device (use Simulator).
- Tapping "Start Scan" button does nothing yet — state wiring is M2's job.

## Context you need from root CLAUDE.md
Read `/CLAUDE.md` before writing any code. Pay special attention to:
- Design tokens section (colours)
- Code style rules (no force-unwraps, @Observable, etc.)
