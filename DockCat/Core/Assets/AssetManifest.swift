import CoreGraphics
import Foundation

struct AssetManifest: Codable, Equatable {
    struct StaticPoses: Codable, Equatable {
        var resting: String
        var held: String
        var dialogue: String
        var transition: String

        enum CodingKeys: String, CodingKey {
            case resting
            case held
            case dialogue
            case transition
        }

        enum LegacyCodingKeys: String, CodingKey {
            case stand
            case stretch
        }

        init(resting: String, held: String, dialogue: String, transition: String) {
            self.resting = resting
            self.held = held
            self.dialogue = dialogue
            self.transition = transition
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
            resting = try container.decodeIfPresent(String.self, forKey: .resting) ?? "poses/resting"
            held = try container.decodeIfPresent(String.self, forKey: .held) ?? "poses/held"
            dialogue = try container.decodeIfPresent(String.self, forKey: .dialogue)
                ?? legacyContainer.decodeIfPresent(String.self, forKey: .stand)
                ?? "poses/dialogue"
            transition = try container.decodeIfPresent(String.self, forKey: .transition)
                ?? legacyContainer.decodeIfPresent(String.self, forKey: .stretch)
                ?? "poses/transition"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(resting, forKey: .resting)
            try container.encode(held, forKey: .held)
            try container.encode(dialogue, forKey: .dialogue)
            try container.encode(transition, forKey: .transition)
        }
    }

    struct Animation: Codable, Equatable {
        var fps: Double
        var frames: [String]
    }

    struct Animations: Codable, Equatable {
        var walk: Animation

        init(walk: Animation) {
            self.walk = walk
        }

        enum CodingKeys: String, CodingKey {
            case walk
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            walk = try container.decodeIfPresent(Animation.self, forKey: .walk)
                ?? Animation(fps: 3, frames: [])
        }
    }

    struct AppIcons: Codable, Equatable {
        var sleep: String
        var empty: String
    }

    struct Anchor: Codable, Equatable {
        var x: Double
        var y: Double
    }

    var id: String
    var name: String
    var author: String
    var canvasWidth: Int
    var canvasHeight: Int
    var defaultAnchor: Anchor
    var poses: StaticPoses
    var animations: Animations
    var appIcons: AppIcons? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case author
        case canvasWidth = "canvas_width"
        case canvasHeight = "canvas_height"
        case defaultAnchor = "default_anchor"
        case poses
        case animations
        case appIcons = "app_icons"
    }

    init(
        id: String,
        name: String,
        author: String,
        canvasWidth: Int,
        canvasHeight: Int,
        defaultAnchor: Anchor,
        poses: StaticPoses,
        animations: Animations,
        appIcons: AppIcons? = nil
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.defaultAnchor = defaultAnchor
        self.poses = poses
        self.animations = animations
        self.appIcons = appIcons
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        author = try container.decode(String.self, forKey: .author)
        canvasWidth = try container.decode(Int.self, forKey: .canvasWidth)
        canvasHeight = try container.decode(Int.self, forKey: .canvasHeight)
        defaultAnchor = try container.decode(Anchor.self, forKey: .defaultAnchor)
        poses = try container.decodeIfPresent(StaticPoses.self, forKey: .poses)
            ?? StaticPoses(resting: "poses/resting", held: "poses/held", dialogue: "poses/dialogue", transition: "poses/transition")
        animations = try container.decodeIfPresent(Animations.self, forKey: .animations)
            ?? Animations(walk: Animation(fps: 3, frames: []))
        appIcons = try container.decodeIfPresent(AppIcons.self, forKey: .appIcons)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(author, forKey: .author)
        try container.encode(canvasWidth, forKey: .canvasWidth)
        try container.encode(canvasHeight, forKey: .canvasHeight)
        try container.encode(defaultAnchor, forKey: .defaultAnchor)
        try container.encode(poses, forKey: .poses)
        try container.encode(animations, forKey: .animations)
        try container.encodeIfPresent(appIcons, forKey: .appIcons)
    }
}
