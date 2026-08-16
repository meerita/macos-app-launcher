import Foundation

struct UsageRecord: Codable, Equatable, Sendable {
    var launchCount: Int
    var lastLaunchedAt: Date?
}

struct SearchResult: Identifiable, Equatable, Sendable {
    var id: String { application.id }
    let application: InstalledApplication
    let score: Int
}

struct ApplicationSearch: Sendable {
    private let maximumResults: Int

    init(maximumResults: Int = 8) {
        self.maximumResults = maximumResults
    }

    func results(
        for query: String,
        in applications: [InstalledApplication],
        usage: [String: UsageRecord],
        now: Date = Date()
    ) -> [SearchResult] {
        let normalizedQuery = Self.normalized(query)
        guard !normalizedQuery.isEmpty else {
            return []
        }

        let scoredResults: [SearchResult]

        scoredResults = applications.compactMap { application in
            guard let baseScore = matchScore(query: normalizedQuery, applicationName: application.name) else {
                return nil
            }
            return SearchResult(
                application: application,
                score: baseScore + usageScore(for: usage[application.id], now: now)
            )
        }

        return scoredResults.sorted { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }

            let lhsUsage = usage[lhs.application.id]
            let rhsUsage = usage[rhs.application.id]
            if lhsUsage?.launchCount != rhsUsage?.launchCount {
                return (lhsUsage?.launchCount ?? 0) > (rhsUsage?.launchCount ?? 0)
            }

            if lhsUsage?.lastLaunchedAt != rhsUsage?.lastLaunchedAt {
                return (lhsUsage?.lastLaunchedAt ?? .distantPast) > (rhsUsage?.lastLaunchedAt ?? .distantPast)
            }

            return lhs.application.name.localizedStandardCompare(rhs.application.name) == .orderedAscending
        }
        .prefix(maximumResults)
        .map { $0 }
    }

    static func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matchScore(query: String, applicationName: String) -> Int? {
        let name = Self.normalized(applicationName)

        if name == query {
            return 10_000
        }

        if name.hasPrefix(query) {
            return 8_000 - min(name.count - query.count, 500)
        }

        if name.split(separator: " ").contains(where: { $0.hasPrefix(query) }) {
            return 6_500 - min(name.count - query.count, 500)
        }

        if name.contains(query) {
            return 5_000 - min(name.count - query.count, 500)
        }

        if let fuzzyScore = fuzzyMatchScore(query: query, name: name) {
            return fuzzyScore
        }

        return nil
    }

    private func fuzzyMatchScore(query: String, name: String) -> Int? {
        var queryIndex = query.startIndex
        var matchedPositions: [String.Index] = []

        for nameIndex in name.indices {
            guard queryIndex < query.endIndex else {
                break
            }
            if name[nameIndex] == query[queryIndex] {
                matchedPositions.append(nameIndex)
                queryIndex = query.index(after: queryIndex)
            }
        }

        guard queryIndex == query.endIndex, let first = matchedPositions.first, let last = matchedPositions.last else {
            return nil
        }

        let span = name.distance(from: first, to: last) + 1
        let compactnessPenalty = max(0, span - query.count) * 25
        let startPenalty = name.distance(from: name.startIndex, to: first) * 15
        return max(1_000, 3_500 - compactnessPenalty - startPenalty)
    }

    private func usageScore(for record: UsageRecord?, now: Date) -> Int {
        guard let record else {
            return 0
        }

        let frequency = min(record.launchCount, 50) * 20
        let recency: Int
        if let lastLaunchedAt = record.lastLaunchedAt {
            let elapsed = max(0, now.timeIntervalSince(lastLaunchedAt))
            let days = elapsed / 86_400
            recency = max(0, 300 - Int(days * 30))
        } else {
            recency = 0
        }

        return frequency + recency
    }
}
