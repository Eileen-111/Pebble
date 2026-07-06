import AppKit

enum PoseKind {
    case resting
    case held
    case dialogue
    case transition
}

struct RenderedPose {
    var image: NSImage?
    var mirrored: Bool
}

final class PoseRenderer {
    private let fileManager: FileManager
    private let pack: CatAssetPack
    private let fallbackPack: CatAssetPack?

    init(pack: CatAssetPack, fallbackPack: CatAssetPack? = nil, fileManager: FileManager = .default) {
        self.pack = pack
        self.fallbackPack = fallbackPack
        self.fileManager = fileManager
    }

    func firstImage(for pose: PoseKind) -> NSImage? {
        poseImages(for: pose).first
    }

    func randomPose(for pose: PoseKind, fallback: PoseKind? = nil) -> RenderedPose {
        let images = poseImages(for: pose)
        let fallbackImages = fallback.map { poseImages(for: $0) } ?? []
        return RenderedPose(image: (images.isEmpty ? fallbackImages : images).randomElement(), mirrored: Bool.random())
    }

    func poseImages(for pose: PoseKind) -> [NSImage] {
        let images = poseImages(for: pose, in: pack)
        guard images.isEmpty, let fallbackPack else {
            return images
        }
        return poseImages(for: pose, in: fallbackPack)
    }

    private func poseImages(for pose: PoseKind, in pack: CatAssetPack) -> [NSImage] {
        let directoryURL: URL
        switch pose {
        case .resting:
            directoryURL = pack.restingPosesDirectoryURL
        case .held:
            directoryURL = pack.heldPosesDirectoryURL
        case .dialogue:
            directoryURL = pack.dialoguePosesDirectoryURL
        case .transition:
            directoryURL = pack.transitionPosesDirectoryURL
        }
        guard let urls = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .compactMap { NSImage(contentsOf: $0) }
    }

    func animationFrames(_ keyPath: KeyPath<AssetManifest.Animations, AssetManifest.Animation>) -> SpriteAnimation {
        let animation = pack.manifest.animations[keyPath: keyPath]
        let frames = walkFramesFromDirectory()
        if !frames.isEmpty {
            return SpriteAnimation(frames: frames, fps: animation.fps, loops: true)
        }

        if let fallbackPack {
            let fallbackFrames = walkFramesFromDirectory(in: fallbackPack)
            if !fallbackFrames.isEmpty {
                let fallbackAnimation = fallbackPack.manifest.animations[keyPath: keyPath]
                return SpriteAnimation(frames: fallbackFrames, fps: fallbackAnimation.fps, loops: true)
            }
        }

        let fallback = firstImage(for: .dialogue).map { [$0] } ?? []
        return SpriteAnimation(frames: fallback, fps: animation.fps, loops: true)
    }

    func walkAnimationSourcePack() -> CatAssetPack? {
        if !walkFramesFromDirectory(in: pack).isEmpty {
            return pack
        }
        if let fallbackPack, !walkFramesFromDirectory(in: fallbackPack).isEmpty {
            return fallbackPack
        }
        return nil
    }

    private func walkFramesFromDirectory() -> [NSImage] {
        walkFramesFromDirectory(in: pack)
    }

    private func walkFramesFromDirectory(in pack: CatAssetPack) -> [NSImage] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: pack.walkAnimationDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .compactMap { NSImage(contentsOf: $0) }
    }
}
