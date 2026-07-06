import Foundation

struct OutingEvent: Codable, Equatable, Identifiable {
    var id: String
    var eventType: String
    var chineseDescription: String
    var englishDescription: String
    var author: String

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case chineseDescription = "chinese_description"
        case englishDescription = "english_description"
        case author
    }
}
