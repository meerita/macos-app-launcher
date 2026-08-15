import Foundation

struct ApplicationCatalog: Sendable {
    func discoverApplications() async -> [InstalledApplication] {
        await Task(priority: .userInitiated) {
            Self.discoverApplicationsSynchronously()
        }.value
    }

    static func discoverApplicationsSynchronously(
        fileManager: FileManager = .default
    ) -> [InstalledApplication] {
        let directories = applicationDirectories(fileManager: fileManager)
        var discovered: [InstalledApplication] = []

        for directory in directories {
            discovered.append(contentsOf: applications(in: directory.url, locationRank: directory.rank, fileManager: fileManager))
        }

        return deduplicated(discovered)
    }

    static func deduplicated(_ applications: [InstalledApplication]) -> [InstalledApplication] {
        var byCanonicalPath: [String: InstalledApplication] = [:]

        for application in applications {
            if let existing = byCanonicalPath[application.canonicalPath] {
                byCanonicalPath[application.canonicalPath] = preferredApplication(between: existing, and: application)
            } else {
                byCanonicalPath[application.canonicalPath] = application
            }
        }

        var byBundleAndName: [String: InstalledApplication] = [:]
        for application in byCanonicalPath.values {
            guard let bundleIdentifier = application.bundleIdentifier else {
                byBundleAndName[application.canonicalPath] = application
                continue
            }

            // Dedupe only exact bundle-identifier/display-name matches. This removes aliases
            // and duplicate copies without hiding intentionally distinct apps with similar names.
            let key = "\(bundleIdentifier)|\(ApplicationSearch.normalized(application.name))"
            if let existing = byBundleAndName[key] {
                byBundleAndName[key] = preferredApplication(between: existing, and: application)
            } else {
                byBundleAndName[key] = application
            }
        }

        return byBundleAndName.values.sorted { lhs, rhs in
            ApplicationSearch.normalized(lhs.name) < ApplicationSearch.normalized(rhs.name)
        }
    }

    private static func applications(
        in directory: URL,
        locationRank: Int,
        fileManager: FileManager
    ) -> [InstalledApplication] {
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey, .isAliasFileKey, .localizedNameKey]
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var applications: [InstalledApplication] = []
        for case let url as URL in enumerator {
            let resourceValues = try? url.resourceValues(forKeys: Set(keys))
            let isDirectory = resourceValues?.isDirectory == true
            guard isDirectory else {
                continue
            }

            if url.pathExtension.caseInsensitiveCompare("app") == .orderedSame {
                if let application = metadata(for: url, locationRank: locationRank) {
                    applications.append(application)
                }
                enumerator.skipDescendants()
                continue
            }

            if resourceValues?.isPackage == true {
                enumerator.skipDescendants()
            }
        }

        return applications
    }

    private static func metadata(for url: URL, locationRank: Int) -> InstalledApplication? {
        guard let bundle = Bundle(url: url) else {
            return nil
        }

        let name = displayName(for: bundle, url: url)
        guard !name.isEmpty else {
            return nil
        }

        return InstalledApplication.make(
            name: name,
            bundleIdentifier: bundle.bundleIdentifier,
            bundleURL: url,
            locationRank: locationRank
        )
    }

    private static func displayName(for bundle: Bundle, url: URL) -> String {
        let infoDictionary = bundle.localizedInfoDictionary ?? bundle.infoDictionary ?? [:]
        if let displayName = infoDictionary["CFBundleDisplayName"] as? String, !displayName.isEmpty {
            return displayName
        }
        if let bundleName = infoDictionary["CFBundleName"] as? String, !bundleName.isEmpty {
            return bundleName
        }
        return url.deletingPathExtension().lastPathComponent
    }

    private static func applicationDirectories(fileManager: FileManager) -> [(url: URL, rank: Int)] {
        var candidates: [(URL, Int)] = []

        let masks: [FileManager.SearchPathDomainMask] = [.userDomainMask, .localDomainMask, .systemDomainMask]
        for (index, mask) in masks.enumerated() {
            candidates.append(contentsOf: fileManager.urls(for: .applicationDirectory, in: mask).map { ($0, index) })
        }

        candidates.append((URL(fileURLWithPath: "/Applications", isDirectory: true), 1))
        candidates.append((URL(fileURLWithPath: "/System/Applications", isDirectory: true), 2))
        candidates.append((fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true), 0))

        var seen: Set<String> = []
        return candidates.compactMap { url, rank in
            let path = url.resolvingSymlinksInPath().standardizedFileURL.path
            guard seen.insert(path).inserted else {
                return nil
            }
            return (url, rank)
        }
    }

    private static func preferredApplication(
        between lhs: InstalledApplication,
        and rhs: InstalledApplication
    ) -> InstalledApplication {
        if lhs.locationRank != rhs.locationRank {
            return lhs.locationRank < rhs.locationRank ? lhs : rhs
        }
        if lhs.canonicalPath != rhs.canonicalPath {
            return lhs.canonicalPath < rhs.canonicalPath ? lhs : rhs
        }
        return lhs.name.localizedStandardCompare(rhs.name) != .orderedDescending ? lhs : rhs
    }
}
