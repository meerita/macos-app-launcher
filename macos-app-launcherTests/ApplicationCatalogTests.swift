import XCTest
@testable import MacOSAppLauncher

final class ApplicationCatalogTests: XCTestCase {
    func testDeduplicationPrefersUserLocationForSameBundleAndName() {
        let systemCopy = InstalledApplication.make(
            name: "Example",
            bundleIdentifier: "com.example.app",
            bundleURL: URL(fileURLWithPath: "/Applications/Example.app"),
            locationRank: 1
        )
        let userCopy = InstalledApplication.make(
            name: "Example",
            bundleIdentifier: "com.example.app",
            bundleURL: URL(fileURLWithPath: "/Users/test/Applications/Example.app"),
            locationRank: 0
        )

        let deduplicated = ApplicationCatalog.deduplicated([systemCopy, userCopy])

        XCTAssertEqual(deduplicated.count, 1)
        XCTAssertEqual(deduplicated.first?.canonicalPath, userCopy.canonicalPath)
    }

    func testDeduplicationKeepsSameBundleIdentifierWithDifferentNames() {
        let first = InstalledApplication.make(
            name: "Example",
            bundleIdentifier: "com.example.app",
            bundleURL: URL(fileURLWithPath: "/Applications/Example.app"),
            locationRank: 1
        )
        let second = InstalledApplication.make(
            name: "Example Beta",
            bundleIdentifier: "com.example.app",
            bundleURL: URL(fileURLWithPath: "/Applications/Example Beta.app"),
            locationRank: 1
        )

        let deduplicated = ApplicationCatalog.deduplicated([first, second])

        XCTAssertEqual(deduplicated.count, 2)
    }
}
