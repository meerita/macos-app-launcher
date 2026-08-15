import Foundation

struct InstalledApplication: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let bundleIdentifier: String?
    let bundleURL: URL
    let canonicalPath: String
    let locationRank: Int

    var displaySubtitle: String? {
        bundleIdentifier
    }
}

extension InstalledApplication {
    static func make(
        name: String,
        bundleIdentifier: String?,
        bundleURL: URL,
        locationRank: Int = 100
    ) -> InstalledApplication {
        let canonicalURL = bundleURL.resolvingSymlinksInPath().standardizedFileURL
        let canonicalPath = canonicalURL.path
        let id: String
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            id = bundleIdentifier
        } else {
            id = canonicalPath
        }
        return InstalledApplication(
            id: id,
            name: name,
            bundleIdentifier: bundleIdentifier,
            bundleURL: bundleURL,
            canonicalPath: canonicalPath,
            locationRank: locationRank
        )
    }
}
