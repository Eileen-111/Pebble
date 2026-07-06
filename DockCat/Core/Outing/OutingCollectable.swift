import Foundation

struct OutingCollectable: Codable, Equatable, Identifiable {
    var id: String
    var chineseName: String
    var englishName: String
    var rarity: Int
    var author: String
    var imagePath: String

    enum CodingKeys: String, CodingKey {
        case id
        case chineseName = "chinese_name"
        case englishName = "english_name"
        case rarity
        case author
        case imagePath = "image_path"
    }
}
