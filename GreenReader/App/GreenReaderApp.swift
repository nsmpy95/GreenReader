import SwiftUI

// MARK: - GreenReaderApp
// App entry point. Creates the single ScanViewModel and injects it into the view hierarchy.
@main
struct GreenReaderApp: App {

    @State private var viewModel = ScanViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
