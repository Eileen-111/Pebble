import Foundation

struct CatAssetPack: Equatable {
    var manifest: AssetManifest
    var rootURL: URL

    var id: String {
        let folderName = rootURL.lastPathComponent
        return folderName == "DefaultCat" ? manifest.id : folderName
    }

    var restingPosesDirectoryURL: URL {
        poseDirectoryURL(manifest.poses.resting)
    }

    var heldPosesDirectoryURL: URL {
        poseDirectoryURL(manifest.poses.held)
    }

    var dialoguePosesDirectoryURL: URL {
        poseDirectoryURL(manifest.poses.dialogue)
    }

    var transitionPosesDirectoryURL: URL {
        poseDirectoryURL(manifest.poses.transition)
    }

    var walkAnimationDirectoryURL: URL {
        rootURL.appendingPathComponent("animations/walk", isDirectory: true)
    }

    var sleepIconURL: URL? {
        iconURL(manifest.appIcons?.sleep)
    }

    var emptyIconURL: URL? {
        iconURL(manifest.appIcons?.empty)
    }

    func url(for relativePath: String) -> URL {
        rootURL.appendingPathComponent(relativePath)
    }

    private func poseDirectoryURL(_ relativePath: String) -> URL {
        rootURL.appendingPathComponent(relativePath, isDirectory: true)
    }

    private func iconURL(_ relativePath: String?) -> URL? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        return rootURL.appendingPathComponent(relativePath)
    }
}
