# GreenReader

LiDAR-powered golf green slope reader for iPhone 15 Pro.

## Requirements
- Xcode 15+
- iOS 17.0 deployment target
- Physical device with LiDAR sensor (iPhone 12 Pro or later)
- No external dependencies — native Apple frameworks only

## Tech stack
| Layer | Technology |
|---|---|
| UI | SwiftUI + `UIViewRepresentable` for `ARSCNView` |
| AR | ARKit 6 (`ARWorldTrackingConfiguration` + `sceneReconstruction`) |
| 3D | SceneKit (vertex-coloured `SCNGeometry`) |
| Math | Custom normal/slope calculation + Accelerate (vDSP) |
| State | `@Observable` (iOS 17) |

## Project structure
```
GreenReader/
├── .claude/
│   ├── settings.json          # Claude Code config
│   └── agents/
│       ├── agent-foundation.md
│       ├── agent-scanner.md
│       ├── agent-math.md
│       ├── agent-ui.md
│       └── agent-polish.md
├── GreenReader/
│   ├── App/                   # Entry point, ContentView, LaunchScreen
│   ├── Modules/
│   │   ├── M1_Foundation/     # LiDAR gate, ARViewContainer
│   │   ├── M2_ScanningEngine/ # ARKit session, mesh capture, hardware guards
│   │   ├── M3_SlopeCalculation/ # Merge, smooth, classify
│   │   ├── M4_VisualizationUI/  # Overlay renderer, all SwiftUI UI
│   │   └── M5_LaunchPolish/     # Onboarding, settings, lifecycle
│   └── Shared/
│       ├── Models/            # MeshData, SlopeData, ScanViewModel
│       └/Utilities/           # DesignTokens, extensions
└── GreenReaderTests/          # Unit tests for M3 math
```

## Building
1. Open `GreenReader.xcodeproj` in Xcode 15
2. Select your physical LiDAR device as the run destination
3. Trust the developer certificate on device if prompted
4. Build & run (`⌘R`)

> The app will show a "LiDAR sensor required" screen on Simulator or
> non-LiDAR devices — this is expected.

## Using with Claude Code

This repository is structured for multi-agent development in Claude Code.
Each module has a dedicated agent specification in `.claude/agents/`.

### Build order (strict — do not skip ahead)
```
M1 → M2 → M3 → M4 → M5
```
Each module depends on the previous. Start a fresh Claude Code session
per module and reference the corresponding agent file.

### Starting a module session
```
# Example for Module 2
claude --agent .claude/agents/agent-scanner.md
```
Or in Claude Code, reference the agent file at the start of the conversation.

## Design reference
Target aesthetic: PuttPro / OnePutt — dark AR camera background, minimal
floating UI, green/white accents, single-purpose screens with large tap
targets for gloved hands.

## LiDAR constraints
- Effective range on grass: **0.2–5 metres**
- The user must walk the green while scanning — not stand at the edge
- Raw grass meshes are noisy — Laplacian smoothing (M3) is not optional
- Very uniform artificial turf may cause ARKit tracking issues

## Licence
MIT
