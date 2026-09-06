import Foundation

enum TargetDisplayMode: String, Codable, CaseIterable {
    case target
    case reading
    case targetAndReading

    var title: String {
        switch self {
        case .target:
            return "Target"

        case .reading:
            return "Reading"

        case .targetAndReading:
            return "Target + Reading"
        }
    }

    var includesReading: Bool {
        switch self {
        case .target:
            return false

        case .reading,
             .targetAndReading:
            return true
        }
    }

    var includesTarget: Bool {
        switch self {
        case .target,
             .targetAndReading:
            return true

        case .reading:
            return false
        }
    }
}
