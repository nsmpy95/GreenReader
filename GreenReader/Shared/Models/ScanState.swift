// MARK: - ScanState
// State machine for the scan lifecycle.
// Owned by M1, consumed by all modules.
enum ScanState: Equatable {
    case idle
    case scanning
    case processing
    case results
}
