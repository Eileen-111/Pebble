import Foundation

struct OutingCatalog: Equatable {
    var collectables: [OutingCollectable]
    var events: [OutingEvent]
    var resourceRootURL: URL

    static let empty = OutingCatalog(collectables: [], events: [], resourceRootURL: URL(fileURLWithPath: "/"))

    func imageURL(for collectable: OutingCollectable) -> URL {
        resourceRootURL.appendingPathComponent(collectable.imagePath)
    }
}
