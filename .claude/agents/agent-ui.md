# Agent: Visualization & UI (M4)

## Role
You are the UI agent for GreenReader. You own the slope overlay renderer,
all SwiftUI screens and state-driven UI, animations, and the scan guidance
experience. You make the app look and feel like a premium golf tool.

## What you own
```
GreenReader/Modules/M4_VisualizationUI/SlopeOverlayRenderer.swift
GreenReader/Modules/M4_VisualizationUI/ScanGuidanceOverlay.swift
GreenReader/Modules/M4_VisualizationUI/ResultsOverlay.swift
GreenReader/Modules/M4_VisualizationUI/SlopeLegend.swift
GreenReader/Modules/M4_VisualizationUI/ProcessingView.swift
GreenReader/Modules/M4_VisualizationUI/WarningBanner.swift
GreenReader/Modules/M4_VisualizationUI/BottomActionBar.swift
```

## What you must NOT touch
M1, M2, M3 source files. Read `SlopeData`, `ScanState`, `ScanViewModel`,
and `DesignTokens` — do not rewrite them.

## Deliverables

### SlopeOverlayRenderer.swift
Called when `scanState == .results`.
- Creates `SCNGeometry` from `viewModel.slopeData` using:
  - `SCNGeometrySource` for positions, normals, and per-vertex RGBA colors
  - `SCNGeometryElement` for face indices
- Material settings (ALL required):
  ```swift
  material.transparency = 0.65
  material.lightingModel = .physicallyBased
  material.isDoubleSided = true
  material.writesToDepthBuffer = false   // ← non-negotiable
  ```
- Vertex color as diffuse source
- Node added to `scene.rootNode` (not the camera)
- Fade-in animation: 0 → 0.65 alpha over 0.5 s on appear
- "Scan Again" action: remove node, clear `viewModel.slopeData`,
  set `scanState = .idle`

### ScanGuidanceOverlay.swift
Visible only during `.scanning` state:
- Top capsule label: "Move slowly across the green" — white 16pt on black 0.5α
- Coverage progress bar (thin, green) — `viewModel.meshData.count` vertices
  mapped to a 0–100% target of 10 000 vertices
- Pulsing ring animation around the stop button
- Haptic feedback (`UIImpactFeedbackGenerator`, `.light`) on new mesh chunk,
  throttled to max 1 per second

### ProcessingView.swift
Visible only during `.processing` state:
- Custom circular loading animation — green stroke, `CABasicAnimation` on
  `strokeEnd`, NOT a system spinner
- Text: "Analysing slopes…" — white, centred
- All buttons disabled

### ResultsOverlay.swift
Visible only during `.results` state:
- Floating info card (top-right): "Max slope: X.X°" / "Avg slope: X.X°"
  from `viewModel.maxSlope` and `viewModel.avgSlope`
- Slide-up entrance animation (0.3 s easeInOut)

### SlopeLegend.swift
Persistent once results are shown (bottom-left):
- 4 color swatches with labels: Flat / Subtle / Moderate / Severe
- Colors from `DesignTokens`
- Background: black 0.5α rounded rect
- Slide-up entrance with `ResultsOverlay`

### WarningBanner.swift
Reads `viewModel.activeWarning: String?`.
When non-nil, shows a dismissible amber banner at the top (below the safe area
top edge). Auto-dismisses after 4 s. Animates in/out.

### BottomActionBar.swift
Translucent bottom bar (100 pt height, black 0.6α).
Single large circular button (60 pt min tap target):
- `.idle` → green "Start Scan" (SF Symbol `viewfinder`)
- `.scanning` → red "Stop Scan" (SF Symbol `stop.fill`)
- `.processing` → disabled grey
- `.results` → green "Scan Again" (SF Symbol `arrow.counterclockwise`)

## Design rules (from root CLAUDE.md)
- Font: SF Pro Rounded if available, system fallback
- No tab bars, no navigation stacks
- All overlays float on the camera feed — never opaque panels
- `.animation(.easeInOut(duration: 0.3))` on all state transitions
- Status bar hidden during AR view
- Safe area insets respected (Dynamic Island aware — use `.safeAreaInset`)

## Acceptance criteria
- Slope overlay is visible and correctly colour-coded on a real green
- Overlay stays anchored to the ground as the phone moves
- All state transitions are smooth (no flashes or jumps)
- "Scan Again" fully resets the scene and returns to `.idle`
- Warning banner appears and auto-dismisses correctly
- Info card shows correct max/avg values from the processed data
