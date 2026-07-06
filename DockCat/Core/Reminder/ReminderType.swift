import Foundation

enum ReminderType: String, Codable, Equatable {
    case water
    case movement

    func message(salutation: String) -> String {
        switch self {
        case .water:
            return "\(salutation)，该喝水啦"
        case .movement:
            return "\(salutation)，该起来走走啦"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "water":
            self = .water
        case "movement", "stand":
            self = .movement
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown reminder type: \(rawValue)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
