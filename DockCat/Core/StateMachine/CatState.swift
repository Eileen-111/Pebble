import Foundation

enum CatState: Equatable, CustomStringConvertible {
    case transitioning
    case walking
    case resting
    case dragged
    case dialogue(ReminderType)
    case outing(OutingPhase)

    var isLongDuration: Bool {
        switch self {
        case .walking, .resting:
            return true
        default:
            return false
        }
    }

    var canBeginDrag: Bool {
        switch self {
        case .walking, .resting, .transitioning:
            return true
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .transitioning: return "transitioning"
        case .walking: return "walking"
        case .resting: return "resting"
        case .dragged: return "dragged"
        case .dialogue(let type): return "dialogue(\(type.rawValue))"
        case .outing(let phase): return "outing(\(phase.rawValue))"
        }
    }
}

enum OutingPhase: String, Codable, Equatable {
    case asking
    case confirmingDeparture
    case leaving
    case away
    case returning
    case returned
}

enum LongDurationState: CaseIterable {
    case walking
    case resting
}
