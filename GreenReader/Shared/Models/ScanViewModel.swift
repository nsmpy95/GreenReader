import Observation

// MARK: - ScanViewModel
// Single source of truth for all app state.
// All modules read from and write to this object.
@Observable
final class ScanViewModel {
    // Core state machine
    var scanState: ScanState = .idle

    // Raw mesh data — populated by M2, cleared after M3 processes it
    var meshData: [MeshData] = []

    // Processed slope data — populated by M3, consumed by M4
    var slopeData: [SlopeData] = []

    // Aggregate stats — populated by M3
    var maxSlope: Float = 0
    var avgSlope: Float = 0

    // Warning banner text — set by M2 hardware guards, rendered by M4
    var activeWarning: String? = nil

    // Settings (read by M2 before haptic feedback)
    var hapticsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    // MARK: - Actions (implemented by respective modules)

    /// Called by M2 after stopScan — releases raw data after processing
    func clearRawMeshData() {
        meshData = []
    }

    /// Called by M4 "Scan Again" — full reset
    func resetToIdle() {
        slopeData = []
        maxSlope  = 0
        avgSlope  = 0
        activeWarning = nil
        scanState = .idle
    }
}
