import ARKit
import UIKit

// MARK: - AppLifecycleManager
// Responds to foreground/background transitions and manages the AR session accordingly.
final class AppLifecycleManager {

    // Weak references to avoid retain cycles.
    private weak var arView: ARSCNView?
    private weak var viewModel: ScanViewModel?

    // Stored observer tokens for clean removal on deinit.
    private var resignToken: NSObjectProtocol?
    private var becomeActiveToken: NSObjectProtocol?

    // MARK: - Setup

    /// Attaches the AR view and view model, then begins lifecycle observation.
    func setup(arView: ARSCNView, viewModel: ScanViewModel) {
        self.arView = arView
        self.viewModel = viewModel
        startObserving()
    }

    // MARK: - Observation

    /// Registers for foreground/background UIApplication notifications.
    func startObserving() {
        let center = NotificationCenter.default

        resignToken = center.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleResignActive()
        }

        becomeActiveToken = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBecomeActive()
        }
    }

    // MARK: - Notification Handlers

    /// Pauses the AR session when the app moves to the background.
    private func handleResignActive() {
        arView?.session.pause()
    }

    /// Resumes the AR session on foreground, but only if a scan is in progress.
    private func handleBecomeActive() {
        guard let arView = arView,
              let viewModel = viewModel,
              viewModel.scanState == .scanning else {
            return
        }

        let configuration = arView.session.configuration ?? ARWorldTrackingConfiguration()
        arView.session.run(configuration)
    }

    // MARK: - Cleanup

    deinit {
        if let resignToken {
            NotificationCenter.default.removeObserver(resignToken)
        }
        if let becomeActiveToken {
            NotificationCenter.default.removeObserver(becomeActiveToken)
        }
    }
}
