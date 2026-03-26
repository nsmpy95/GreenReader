import SwiftUI

// MARK: - Design Tokens
// Single source of truth for all visual constants.
// All modules import this file. Never hardcode values elsewhere.

extension Color {
    // Brand
    static let greenAccent  = Color(hex: "#00C853")
    static let darkBg       = Color(hex: "#1A1A1A")

    // Slope classification
    static let slopeFlat     = Color(hex: "#4CAF50")
    static let slopeSubtle   = Color(hex: "#FFEB3B")
    static let slopeModerate = Color(hex: "#FF9800")
    static let slopeSevere   = Color(hex: "#F44336")

    // UI chrome
    static let overlayBar    = Color.black.opacity(0.6)
    static let overlayPanel  = Color.black.opacity(0.5)
    static let warningAmber  = Color(hex: "#FF9800")

    // SIMD equivalents for SceneKit vertex colours
    static let slopeFlatSIMD:     SIMD4<Float> = [0.298, 0.686, 0.314, 1]
    static let slopeSubtleSIMD:   SIMD4<Float> = [1.000, 0.922, 0.231, 1]
    static let slopeModerateSIMD: SIMD4<Float> = [1.000, 0.596, 0.000, 1]
    static let slopeSevereSIMD:   SIMD4<Float> = [0.957, 0.263, 0.212, 1]
}

extension CGFloat {
    static let buttonSize:  CGFloat = 60
    static let bottomBarH: CGFloat = 100
    static let cornerSm:   CGFloat = 8
    static let cornerMd:   CGFloat = 12
}

// MARK: - Hex initialiser (private utility)
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let int = UInt64(hex, radix: 16) ?? 0
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
