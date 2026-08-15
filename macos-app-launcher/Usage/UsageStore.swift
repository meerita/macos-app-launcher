import Foundation

@MainActor
final class UsageStore {
    private let key = "ApplicationUsageHistory"
    private let userDefaults: UserDefaults

    private(set) var records: [String: UsageRecord]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.records = Self.loadRecords(from: userDefaults, key: key)
    }

    func recordLaunch(of application: InstalledApplication, at date: Date = Date()) {
        var record = records[application.id] ?? UsageRecord(launchCount: 0, lastLaunchedAt: nil)
        record.launchCount += 1
        record.lastLaunchedAt = date
        records[application.id] = record
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }

    private static func loadRecords(from userDefaults: UserDefaults, key: String) -> [String: UsageRecord] {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: UsageRecord].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
