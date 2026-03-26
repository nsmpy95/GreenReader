# Agent: Launch, Onboarding & Polish (M5)

## Role
You are the Polish agent for GreenReader. You own everything the user sees
before they scan and everything that makes the app feel production-ready:
launch screen, first-run onboarding, settings, background handling, and the
remaining real-world edge cases not covered by M2's hardware guards.

## What you own
```
GreenReader/Modules/M5_LaunchPolish/OnboardingView.swift
GreenReader/Modules/M5_LaunchPolish/SettingsSheet.swift
GreenReader/Modules/M5_LaunchPolish/AppLifecycleManager.swift
GreenReader/App/LaunchScreen.storyboard   (or LaunchScreenView.swift)
GreenReader/App/Info.plist                (keys only — no Xcode project edits)
```

## What you must NOT touch
Any M1–M4 file. You may READ ScanViewModel and DesignTokens.

## Deliverables

### LaunchScreen
SwiftUI-compatible launch screen:
- Background: `#1A1A1A`
- App name "GreenReader" — green `#00C853`, 32pt bold, centred
- Subtitle "LiDAR Green Reading" — white, 16pt
- No images, no logos — typographic only

### OnboardingView.swift
- Shown on first launch only (`UserDefaults` key `"onboardingComplete"`)
- Single screen, 4 steps displayed vertically:
  1. "Stand on the green"
  2. "Tap Start Scan"
  3. "Walk slowly across the green"
  4. "Tap Stop to see the slope map"
- Large "Got it" button (green, full width) dismisses and sets the defaults key
- Dark background, white text, green step numbers

### SettingsSheet.swift
Accessible via gear icon (top-left of `ContentView`, SF Symbol `gearshape`).
Presented as a `.sheet`.
Contents:
- Toggle: "Haptic Feedback" → `UserDefaults` key `"hapticsEnabled"` (default: true)
  M2's `HardwareGuards` reads this key before triggering haptics
- Info row: "Device" → `UIDevice.current.model`
- Info row: "LiDAR" → "Available" (only shown if we got past the gate)
- Button: "How to scan" → re-presents `OnboardingView`

### AppLifecycleManager.swift
Observes `UIApplication` notifications:
- `willResignActive` → pause AR session (`arView.session.pause()`)
- `didBecomeActive` + `scanState == .scanning` → resume AR session
- Never resume if `scanState != .scanning` (don't resume mid-results)

### Info.plist keys to document
List these keys (the developer adds them in Xcode):
```
NSCameraUsageDescription  "GreenReader needs camera access to scan the green."
```
No other permissions required.

## Acceptance criteria
- Onboarding appears on first launch, never again after "Got it"
- Settings sheet opens, haptic toggle persists across app restarts
- Backgrounding the app pauses the AR session; foregrounding resumes it
  only if a scan was active
- Launch screen matches spec (dark bg, green title, white subtitle)
- "How to scan" successfully re-shows onboarding from settings
