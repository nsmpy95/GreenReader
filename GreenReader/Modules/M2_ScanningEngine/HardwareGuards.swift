import ARKit
import UIKit

// MARK: - HardwareGuards
// Monitors device hardware state during a scanning session and triggers warnings
// or auto-stops when thresholds are exceeded.
final class HardwareGuards {

    // MARK: - Dependencies

    private weak var viewModel: ScanViewModel?
    private let stopScanCallback: () -> Void

    // MARK: - Low-light tracking

    /// Timestamp when continuous low-light condition first began; nil when adequate.
    private var lowLightStartDate: Date? = nil
    private let lowLightThresholdLux: CGFloat = 500
    private let lowLightWarningDelay: TimeInterval = 3.0

    // MARK: - Vertex-cap flag (fire once per scan)

    private var vertexCapWarningFired = false

    // MARK: - Thermal observer

    private var thermalObserver: NSObjectProtocol?

    // MARK: - Init

    init(viewModel: ScanViewModel, stopScanCallback: @escaping () -> Void) {
        self.viewModel        = viewModel
        self.stopScanCallback = stopScanCallback
        registerThermalObserver()
    }

    deinit {
        if let observer = thermalObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - 1. Thermal guard

    private func registerThermalObserver() {
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object:  nil,
            queue:   .main
        ) { [weak self] _ in
            self?.evaluateThermalState()
        }
    }

    private func evaluateThermalState() {
        let state = ProcessInfo.processInfo.thermalState
        guard state == .serious || state == .critical else { return }
        guard viewModel?.scanState == .scanning else { return }

        stopScanCallback()
        Task { @MainActor [weak viewModel] in
            viewModel?.activeWarning = "Device is warm. Scanning paused."
        }
    }

    // MARK: - 2. Vertex cap guard

    /// Checks whether the cumulative vertex count has exceeded the 100,000-vertex cap.
    func checkVertexCap(totalVertices: Int) {
        guard !vertexCapWarningFired else { return }
        guard totalVertices > 100_000 else { return }
        guard viewModel?.scanState == .scanning else { return }

        vertexCapWarningFired = true
        stopScanCallback()
        Task { @MainActor [weak viewModel] in
            viewModel?.activeWarning = "Scan area complete. Tap Stop to process."
        }
    }

    // MARK: - 3. Low-light guard

    /// Evaluates ambient light intensity; warns after 3 continuous seconds below 500 lux.
    func checkLightEstimate(_ intensity: CGFloat) {
        guard viewModel?.scanState == .scanning else { return }

        if intensity < lowLightThresholdLux {
            if lowLightStartDate == nil {
                lowLightStartDate = Date()
            } else if let start = lowLightStartDate,
                      Date().timeIntervalSince(start) >= lowLightWarningDelay {
                // Warning only — do not stop the scan
                Task { @MainActor [weak viewModel] in
                    viewModel?.activeWarning = "Low light detected. Results may be less accurate."
                }
                // Reset so the warning isn't re-posted on every subsequent frame
                lowLightStartDate = nil
            }
        } else {
            // Light is adequate — reset the timer
            lowLightStartDate = nil
        }
    }

    // MARK: - 4. Tracking loss guard

    /// Reacts to ARCamera tracking state changes and surfaces actionable user hints.
    func handleTrackingState(_ state: ARCamera.TrackingState) {
        guard viewModel?.scanState == .scanning else { return }

        switch state {
        case .limited(.insufficientFeatures), .notAvailable:
            Task { @MainActor [weak viewModel] in
                viewModel?.activeWarning = "Point at a textured surface"
            }
        default:
            // Clear tracking-related warning when tracking recovers
            Task { @MainActor [weak viewModel] in
                if viewModel?.activeWarning == "Point at a textured surface" {
                    viewModel?.activeWarning = nil
                }
            }
        }
    }

    // MARK: - 5. Battery guard

    /// Checks battery level once before a scan begins and surfaces a low-battery advisory.
    func checkBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel  // -1 if monitoring unavailable

        guard level >= 0 else { return }          // simulator or unavailable
        guard level < 0.15 else { return }

        Task { @MainActor [weak viewModel] in
            viewModel?.activeWarning = "Low battery. Consider charging."
        }
    }
}
