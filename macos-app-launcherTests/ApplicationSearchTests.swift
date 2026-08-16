import XCTest
@testable import MacOSAppLauncher

final class ApplicationSearchTests: XCTestCase {
    private let search = ApplicationSearch(maximumResults: 10)

    func testNormalizationIsCaseWhitespaceAndDiacriticInsensitive() {
        XCTAssertEqual(ApplicationSearch.normalized("  SáFARI   Preview  "), "safari preview")
    }

    func testExactMatchRanksAbovePrefixMatch() {
        let results = search.results(for: "safari", in: [
            app("Safari Preview"),
            app("Safari")
        ], usage: [:])

        XCTAssertEqual(results.map(\.application.name), ["Safari", "Safari Preview"])
    }

    func testPrefixMatchRanksAboveSubstringMatch() {
        let results = search.results(for: "ter", in: [
            app("Outer Terminal"),
            app("Terminal")
        ], usage: [:])

        XCTAssertEqual(results.map(\.application.name), ["Terminal", "Outer Terminal"])
    }

    func testWordPrefixRanksAboveSubstringMatch() {
        let results = search.results(for: "code", in: [
            app("Encoder"),
            app("Visual Studio Code")
        ], usage: [:])

        XCTAssertEqual(results.map(\.application.name), ["Visual Studio Code", "Encoder"])
    }

    func testSubstringRanksAboveFuzzyMatch() {
        let results = search.results(for: "note", in: [
            app("Noble Text Editor"),
            app("Keynote")
        ], usage: [:])

        XCTAssertEqual(results.map(\.application.name).first, "Keynote")
    }

    func testFuzzyMatchFindsOrderedCharacters() {
        let results = search.results(for: "vsc", in: [
            app("Visual Studio Code"),
            app("Safari")
        ], usage: [:])

        XCTAssertEqual(results.map(\.application.name), ["Visual Studio Code"])
    }

    func testEmptyQueryReturnsNoResults() {
        let now = Date()
        let terminal = app("Terminal", bundleIdentifier: "com.apple.Terminal")
        let safari = app("Safari", bundleIdentifier: "com.apple.Safari")

        let results = search.results(
            for: "",
            in: [safari, terminal],
            usage: [
                terminal.id: UsageRecord(launchCount: 4, lastLaunchedAt: now)
            ],
            now: now
        )

        XCTAssertTrue(results.isEmpty)
    }

    func testUsageBreaksTiesWithinSameMatchClass() {
        let now = Date()
        let code = app("Code", bundleIdentifier: "com.microsoft.VSCode")
        let coder = app("Coder", bundleIdentifier: "com.example.Coder")

        let results = search.results(
            for: "cod",
            in: [coder, code],
            usage: [
                code.id: UsageRecord(launchCount: 10, lastLaunchedAt: now)
            ],
            now: now
        )

        XCTAssertEqual(results.map(\.application.name).first, "Code")
    }

    private func app(_ name: String, bundleIdentifier: String? = nil) -> InstalledApplication {
        InstalledApplication.make(
            name: name,
            bundleIdentifier: bundleIdentifier ?? "test.\(name.replacingOccurrences(of: " ", with: "-"))",
            bundleURL: URL(fileURLWithPath: "/Applications/\(name).app"),
            locationRank: 1
        )
    }
}
