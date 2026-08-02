import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var hasSeenOnboarding: Bool {
        didSet { persist() }
    }

    @Published var cloudAlertThreshold: Double {
        didSet {
            guard !isLoading, !syncingThreshold else { return }
            syncingThreshold = true
            if abs(alertThreshold - cloudAlertThreshold) > 0.001 {
                alertThreshold = cloudAlertThreshold
            }
            syncingThreshold = false
            persist()
        }
    }

    @Published var alertThreshold: Double {
        didSet {
            guard !isLoading, !syncingThreshold else { return }
            syncingThreshold = true
            if abs(cloudAlertThreshold - alertThreshold) > 0.001 {
                cloudAlertThreshold = alertThreshold
            }
            syncingThreshold = false
            persist()
        }
    }

    @Published var cloudDataHistory: [CloudHistoryPoint] {
        didSet { persist() }
    }

    @Published var cloudLog: [CloudLogEntry] {
        didSet { persist() }
    }

    @Published var cloudData: [String: Double] {
        didSet { persist() }
    }

    @Published var itemsCreated: Int {
        didSet { persist() }
    }

    @Published var sessionsCompleted: Int {
        didSet { persist() }
    }

    @Published var streakDays: Int {
        didSet { persist() }
    }

    @Published var lastActivityDate: String {
        didSet { persist() }
    }

    @Published var achievementsUnlocked: Set<AchievementID> {
        didSet { persist() }
    }

    @Published var currentCoverage: Double {
        didSet { persist() }
    }

    @Published var soundEnabled: Bool {
        didSet { persist() }
    }

    @Published var hapticEnabled: Bool {
        didSet { persist() }
    }

    @Published var reminderEnabled: Bool {
        didSet {
            persist()
            ReminderScheduler.reschedule(enabled: reminderEnabled, hour: reminderHour, minute: reminderMinute)
        }
    }

    @Published var reminderHour: Int {
        didSet {
            persist()
            ReminderScheduler.reschedule(enabled: reminderEnabled, hour: reminderHour, minute: reminderMinute)
        }
    }

    @Published var reminderMinute: Int {
        didSet {
            persist()
            ReminderScheduler.reschedule(enabled: reminderEnabled, hour: reminderHour, minute: reminderMinute)
        }
    }

    @Published var smartAlertEnabled: Bool {
        didSet { persist() }
    }

    @Published var smartAlertDays: Int {
        didSet { persist() }
    }

    @Published var instrumentTheme: InstrumentTheme {
        didSet { persist() }
    }

    @Published var dismissedTips: Set<String> {
        didSet { persist() }
    }

    @Published var pendingAchievementBanner: AchievementID?
    @Published var pendingAlertBanner: String?
    @Published var pendingTip: CoachTip?
    @Published var selectedTab: MainTab = .sky
    @Published var presentLogSheet: Bool = false

    private let defaultsKey = "AppDataStore.v1"
    private var achievementQueue: [AchievementID] = []
    private var isLoading = false
    private var syncingThreshold = false

    private init() {
        isLoading = true
        let snapshot = Self.loadSnapshot()
        hasSeenOnboarding = snapshot.hasSeenOnboarding
        cloudAlertThreshold = snapshot.cloudAlertThreshold
        alertThreshold = snapshot.alertThreshold
        cloudDataHistory = snapshot.cloudDataHistory
        cloudLog = snapshot.cloudLog.sorted { $0.date > $1.date }
        cloudData = snapshot.cloudData
        itemsCreated = snapshot.itemsCreated
        sessionsCompleted = snapshot.sessionsCompleted
        streakDays = snapshot.streakDays
        lastActivityDate = snapshot.lastActivityDate
        achievementsUnlocked = Set(snapshot.achievementsUnlocked.compactMap(AchievementID.init(rawValue:)))
        currentCoverage = snapshot.currentCoverage
        soundEnabled = snapshot.soundEnabled
        hapticEnabled = snapshot.hapticEnabled
        reminderHour = snapshot.reminderHour
        reminderMinute = snapshot.reminderMinute
        reminderEnabled = snapshot.reminderEnabled
        smartAlertEnabled = snapshot.smartAlertEnabled
        smartAlertDays = max(2, snapshot.smartAlertDays)
        instrumentTheme = InstrumentTheme(rawValue: snapshot.instrumentTheme) ?? .radar
        dismissedTips = Set(snapshot.dismissedTips)
        if abs(cloudAlertThreshold - alertThreshold) > 0.01 {
            syncingThreshold = true
            alertThreshold = cloudAlertThreshold
            syncingThreshold = false
        }
        isLoading = false
        ReminderScheduler.reschedule(enabled: reminderEnabled, hour: reminderHour, minute: reminderMinute)
    }

    var averageCoverage: Double {
        guard !cloudLog.isEmpty else { return 0 }
        return cloudLog.map(\.coverage).reduce(0, +) / Double(cloudLog.count)
    }

    var peakCoverage: Double {
        cloudLog.map(\.coverage).max() ?? 0
    }

    var clearestEntry: CloudLogEntry? {
        cloudLog.min { $0.coverage < $1.coverage }
    }

    var sortedHistory: [CloudHistoryPoint] {
        cloudDataHistory.sorted { $0.date < $1.date }
    }

    var knownLocations: [String] {
        let names = cloudLog.map(\.location).filter { !$0.isEmpty }
        return Array(Set(names)).sorted()
    }

    var reminderDate: Date {
        get {
            var comps = DateComponents()
            comps.hour = reminderHour
            comps.minute = reminderMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            reminderHour = Calendar.current.component(.hour, from: newValue)
            reminderMinute = Calendar.current.component(.minute, from: newValue)
        }
    }

    // MARK: - Logging

    @discardableResult
    func logObservation(
        coverage: Double,
        note: String = "",
        date: Date = Date(),
        tags: [ConditionTag] = [],
        location: String = "",
        period: ObservationPeriod? = nil,
        countsAsSession: Bool = true
    ) -> CloudLogEntry {
        let clamped = min(max(coverage, 0), 100)
        let resolvedPeriod = period ?? ObservationPeriod.from(date: date)
        let entry = CloudLogEntry(
            date: date,
            coverage: clamped,
            note: note,
            tags: tags,
            location: location,
            period: resolvedPeriod
        )
        cloudLog.insert(entry, at: 0)
        cloudDataHistory.append(CloudHistoryPoint(id: entry.id, date: date, coverage: clamped))
        let key = Self.dayKey(for: date)
        cloudData[key] = clamped
        currentCoverage = clamped
        itemsCreated += 1
        if countsAsSession {
            sessionsCompleted += 1
        }
        recordActivity()
        HapticFeedback.medium()
        HapticFeedback.playCompleteSound()

        if clamped >= cloudAlertThreshold {
            pendingAlertBanner = "Cloud cover \(Int(clamped))% reached your \(Int(cloudAlertThreshold))% alert level."
            HapticFeedback.warning()
            HapticFeedback.playAlertSound()
        }

        evaluateSmartAlert()
        evaluateAchievements()
        evaluateTips()
        return entry
    }

    func addPastData(
        coverage: Double,
        date: Date,
        note: String = "",
        tags: [ConditionTag] = [],
        location: String = "",
        period: ObservationPeriod? = nil
    ) {
        logObservation(
            coverage: coverage,
            note: note,
            date: date,
            tags: tags,
            location: location,
            period: period,
            countsAsSession: true
        )
    }

    func deleteLogEntry(_ entry: CloudLogEntry) {
        cloudLog.removeAll { $0.id == entry.id }
        cloudDataHistory.removeAll { $0.id == entry.id }
        rebuildCloudDataMapping()
    }

    func updateLogEntry(
        _ entry: CloudLogEntry,
        coverage: Double,
        note: String,
        date: Date,
        tags: [ConditionTag],
        location: String,
        period: ObservationPeriod
    ) {
        guard let index = cloudLog.firstIndex(where: { $0.id == entry.id }) else { return }
        cloudLog[index].coverage = min(max(coverage, 0), 100)
        cloudLog[index].note = note
        cloudLog[index].date = date
        cloudLog[index].tags = tags
        cloudLog[index].location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        cloudLog[index].period = period
        rebuildCloudDataMapping()
        cloudDataHistory = cloudLog.map { CloudHistoryPoint(id: $0.id, date: $0.date, coverage: $0.coverage) }
    }

    func updateAlertThreshold(_ value: Double) {
        let clamped = min(max(value, 0), 100)
        syncingThreshold = true
        cloudAlertThreshold = clamped
        alertThreshold = clamped
        syncingThreshold = false
        persist()
    }

    func enableReminder(at date: Date) {
        reminderHour = Calendar.current.component(.hour, from: date)
        reminderMinute = Calendar.current.component(.minute, from: date)
        ReminderScheduler.requestAuthorization { [weak self] granted in
            guard let self else { return }
            self.reminderEnabled = granted
            if granted {
                ReminderScheduler.reschedule(enabled: true, hour: self.reminderHour, minute: self.reminderMinute)
            }
        }
    }

    func dismissTip() {
        if let tip = pendingTip {
            dismissedTips.insert(tip.rawValue)
        }
        pendingTip = nil
        evaluateTips()
    }

    private func rebuildCloudDataMapping() {
        var map: [String: Double] = [:]
        for entry in cloudLog.sorted(by: { $0.date < $1.date }) {
            map[Self.dayKey(for: entry.date)] = entry.coverage
        }
        cloudData = map
        if let latest = cloudLog.sorted(by: { $0.date > $1.date }).first {
            currentCoverage = latest.coverage
        } else {
            currentCoverage = 0
        }
    }

    // MARK: - Analytics helpers

    func filteredLog(
        search: String = "",
        tag: ConditionTag? = nil,
        location: String? = nil,
        period: ObservationPeriod? = nil,
        minCoverage: Double = 0,
        maxCoverage: Double = 100
    ) -> [CloudLogEntry] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cloudLog.filter { entry in
            if let tag, !entry.tags.contains(tag) { return false }
            if let location, !location.isEmpty, entry.location.caseInsensitiveCompare(location) != .orderedSame { return false }
            if let period, entry.period != period { return false }
            if entry.coverage < minCoverage || entry.coverage > maxCoverage { return false }
            if query.isEmpty { return true }
            let haystack = [
                entry.note,
                entry.location,
                entry.period.title,
                entry.tags.map(\.title).joined(separator: " "),
                "\(Int(entry.coverage))"
            ].joined(separator: " ").lowercased()
            return haystack.contains(query)
        }
    }

    func periodComparison(weeksAgo: Int) -> PeriodComparison {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let label = weeksAgo == 0 ? "This week" : "Last week"
        guard
            let rangeEnd = calendar.date(byAdding: .day, value: 1 - (7 * weeksAgo), to: todayStart),
            let rangeStart = calendar.date(byAdding: .day, value: 1 - (7 * (weeksAgo + 1)), to: todayStart)
        else {
            return .empty
        }
        let entries = cloudLog.filter { $0.date >= rangeStart && $0.date < rangeEnd }
        guard !entries.isEmpty else {
            return PeriodComparison(label: label, count: 0, average: 0, peak: 0)
        }
        let avg = entries.map(\.coverage).reduce(0, +) / Double(entries.count)
        let peak = entries.map(\.coverage).max() ?? 0
        return PeriodComparison(label: label, count: entries.count, average: avg, peak: peak)
    }

    func averageCoverage(for period: ObservationPeriod) -> Double {
        let entries = cloudLog.filter { $0.period == period }
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.coverage).reduce(0, +) / Double(entries.count)
    }

    func count(for period: ObservationPeriod) -> Int {
        cloudLog.filter { $0.period == period }.count
    }

    func consecutiveDaysAboveThreshold() -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())
        var streak = 0
        while true {
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let dayEntries = cloudLog.filter { $0.date >= day && $0.date < next }
            guard let maxCover = dayEntries.map(\.coverage).max(), maxCover >= cloudAlertThreshold else {
                break
            }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
            if streak > 365 { break }
        }
        return streak
    }

    // MARK: - Achievements / Alerts / Tips

    func evaluateAchievements() {
        let checks: [(AchievementID, Bool)] = [
            (.firstCheck, itemsCreated >= 1),
            (.alertSetup, itemsCreated >= 5),
            (.regularObserver, streakDays >= 7),
            (.skyWatcher, sessionsCompleted >= 10),
            (.clearChoice, itemsCreated >= 3),
            (.persistentTracker, streakDays >= 30),
            (.cloudEnthusiast, itemsCreated >= 50),
            (.insightSeeker, sessionsCompleted >= 14)
        ]

        for (id, met) in checks where met && !achievementsUnlocked.contains(id) {
            achievementsUnlocked.insert(id)
            enqueueAchievement(id)
        }
    }

    func evaluateSmartAlert() {
        guard smartAlertEnabled, pendingAlertBanner == nil else { return }
        let streak = consecutiveDaysAboveThreshold()
        guard streak >= smartAlertDays else { return }
        let today = Self.dayKey(for: Date())
        let lastKey = "smartAlert.lastDay"
        if UserDefaults.standard.string(forKey: lastKey) == today { return }
        UserDefaults.standard.set(today, forKey: lastKey)
        pendingAlertBanner = "Smart alert: \(streak) days in a row above \(Int(cloudAlertThreshold))% cover."
        HapticFeedback.warning()
        HapticFeedback.playAlertSound()
    }

    func evaluateTips() {
        guard pendingTip == nil, pendingAchievementBanner == nil else { return }
        let candidates: [(CoachTip, Bool)] = [
            (.firstLog, itemsCreated >= 1),
            (.usePresets, itemsCreated >= 2),
            (.readCharts, itemsCreated >= 3),
            (.setReminder, itemsCreated >= 4 && !reminderEnabled)
        ]
        for (tip, met) in candidates where met && !dismissedTips.contains(tip.rawValue) {
            pendingTip = tip
            return
        }
    }

    func dismissAchievementBanner() {
        pendingAchievementBanner = nil
        if !achievementQueue.isEmpty {
            let next = achievementQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.pendingAchievementBanner = next
            }
        } else {
            evaluateTips()
        }
    }

    func dismissAlertBanner() {
        pendingAlertBanner = nil
    }

    private func enqueueAchievement(_ id: AchievementID) {
        if pendingAchievementBanner == nil {
            pendingAchievementBanner = id
        } else {
            achievementQueue.append(id)
        }
    }

    // MARK: - Streak / Reset

    func recordActivity() {
        let today = Self.dayKey(for: Date())
        if lastActivityDate.isEmpty {
            streakDays = 1
            lastActivityDate = today
            evaluateAchievements()
            return
        }
        if lastActivityDate == today {
            evaluateAchievements()
            return
        }
        if let last = Self.date(from: lastActivityDate),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           Self.dayKey(for: yesterday) == Self.dayKey(for: last) {
            streakDays += 1
        } else {
            streakDays = 1
        }
        lastActivityDate = today
        evaluateAchievements()
    }

    func resetAllData() {
        isLoading = true
        hasSeenOnboarding = false
        cloudAlertThreshold = 70
        alertThreshold = 70
        cloudDataHistory = []
        cloudLog = []
        cloudData = [:]
        itemsCreated = 0
        sessionsCompleted = 0
        streakDays = 0
        lastActivityDate = ""
        achievementsUnlocked = []
        currentCoverage = 0
        soundEnabled = true
        hapticEnabled = true
        reminderEnabled = false
        reminderHour = 9
        reminderMinute = 0
        smartAlertEnabled = false
        smartAlertDays = 3
        instrumentTheme = .radar
        dismissedTips = []
        pendingAchievementBanner = nil
        pendingAlertBanner = nil
        pendingTip = nil
        achievementQueue = []
        selectedTab = .sky
        presentLogSheet = false
        isLoading = false
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        ReminderScheduler.reschedule(enabled: false, hour: 9, minute: 0)
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    // MARK: - Persistence

    private func persist() {
        guard !isLoading else { return }
        if syncingThreshold { return }
        let snapshot = Snapshot(
            hasSeenOnboarding: hasSeenOnboarding,
            cloudAlertThreshold: cloudAlertThreshold,
            alertThreshold: alertThreshold,
            cloudDataHistory: cloudDataHistory,
            cloudLog: cloudLog,
            cloudData: cloudData,
            itemsCreated: itemsCreated,
            sessionsCompleted: sessionsCompleted,
            streakDays: streakDays,
            lastActivityDate: lastActivityDate,
            achievementsUnlocked: achievementsUnlocked.map(\.rawValue),
            currentCoverage: currentCoverage,
            soundEnabled: soundEnabled,
            hapticEnabled: hapticEnabled,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            smartAlertEnabled: smartAlertEnabled,
            smartAlertDays: smartAlertDays,
            instrumentTheme: instrumentTheme.rawValue,
            dismissedTips: Array(dismissedTips)
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static func loadSnapshot() -> Snapshot {
        guard let data = UserDefaults.standard.data(forKey: "AppDataStore.v1"),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func date(from dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

    private struct Snapshot: Codable {
        var hasSeenOnboarding: Bool
        var cloudAlertThreshold: Double
        var alertThreshold: Double
        var cloudDataHistory: [CloudHistoryPoint]
        var cloudLog: [CloudLogEntry]
        var cloudData: [String: Double]
        var itemsCreated: Int
        var sessionsCompleted: Int
        var streakDays: Int
        var lastActivityDate: String
        var achievementsUnlocked: [String]
        var currentCoverage: Double
        var soundEnabled: Bool
        var hapticEnabled: Bool
        var reminderEnabled: Bool
        var reminderHour: Int
        var reminderMinute: Int
        var smartAlertEnabled: Bool
        var smartAlertDays: Int
        var instrumentTheme: String
        var dismissedTips: [String]

        enum CodingKeys: String, CodingKey {
            case hasSeenOnboarding, cloudAlertThreshold, alertThreshold
            case cloudDataHistory, cloudLog, cloudData
            case itemsCreated, sessionsCompleted, streakDays, lastActivityDate
            case achievementsUnlocked, currentCoverage
            case soundEnabled, hapticEnabled
            case reminderEnabled, reminderHour, reminderMinute
            case smartAlertEnabled, smartAlertDays, instrumentTheme, dismissedTips
        }

        init(
            hasSeenOnboarding: Bool,
            cloudAlertThreshold: Double,
            alertThreshold: Double,
            cloudDataHistory: [CloudHistoryPoint],
            cloudLog: [CloudLogEntry],
            cloudData: [String: Double],
            itemsCreated: Int,
            sessionsCompleted: Int,
            streakDays: Int,
            lastActivityDate: String,
            achievementsUnlocked: [String],
            currentCoverage: Double,
            soundEnabled: Bool,
            hapticEnabled: Bool,
            reminderEnabled: Bool,
            reminderHour: Int,
            reminderMinute: Int,
            smartAlertEnabled: Bool,
            smartAlertDays: Int,
            instrumentTheme: String,
            dismissedTips: [String]
        ) {
            self.hasSeenOnboarding = hasSeenOnboarding
            self.cloudAlertThreshold = cloudAlertThreshold
            self.alertThreshold = alertThreshold
            self.cloudDataHistory = cloudDataHistory
            self.cloudLog = cloudLog
            self.cloudData = cloudData
            self.itemsCreated = itemsCreated
            self.sessionsCompleted = sessionsCompleted
            self.streakDays = streakDays
            self.lastActivityDate = lastActivityDate
            self.achievementsUnlocked = achievementsUnlocked
            self.currentCoverage = currentCoverage
            self.soundEnabled = soundEnabled
            self.hapticEnabled = hapticEnabled
            self.reminderEnabled = reminderEnabled
            self.reminderHour = reminderHour
            self.reminderMinute = reminderMinute
            self.smartAlertEnabled = smartAlertEnabled
            self.smartAlertDays = smartAlertDays
            self.instrumentTheme = instrumentTheme
            self.dismissedTips = dismissedTips
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
            cloudAlertThreshold = try c.decodeIfPresent(Double.self, forKey: .cloudAlertThreshold) ?? 70
            alertThreshold = try c.decodeIfPresent(Double.self, forKey: .alertThreshold) ?? 70
            cloudDataHistory = try c.decodeIfPresent([CloudHistoryPoint].self, forKey: .cloudDataHistory) ?? []
            cloudLog = try c.decodeIfPresent([CloudLogEntry].self, forKey: .cloudLog) ?? []
            cloudData = try c.decodeIfPresent([String: Double].self, forKey: .cloudData) ?? [:]
            itemsCreated = try c.decodeIfPresent(Int.self, forKey: .itemsCreated) ?? 0
            sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
            streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
            lastActivityDate = try c.decodeIfPresent(String.self, forKey: .lastActivityDate) ?? ""
            achievementsUnlocked = try c.decodeIfPresent([String].self, forKey: .achievementsUnlocked) ?? []
            currentCoverage = try c.decodeIfPresent(Double.self, forKey: .currentCoverage) ?? 0
            soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
            hapticEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticEnabled) ?? true
            reminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
            reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 9
            reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
            smartAlertEnabled = try c.decodeIfPresent(Bool.self, forKey: .smartAlertEnabled) ?? false
            smartAlertDays = try c.decodeIfPresent(Int.self, forKey: .smartAlertDays) ?? 3
            instrumentTheme = try c.decodeIfPresent(String.self, forKey: .instrumentTheme) ?? InstrumentTheme.radar.rawValue
            dismissedTips = try c.decodeIfPresent([String].self, forKey: .dismissedTips) ?? []
        }

        static let empty = Snapshot(
            hasSeenOnboarding: false,
            cloudAlertThreshold: 70,
            alertThreshold: 70,
            cloudDataHistory: [],
            cloudLog: [],
            cloudData: [:],
            itemsCreated: 0,
            sessionsCompleted: 0,
            streakDays: 0,
            lastActivityDate: "",
            achievementsUnlocked: [],
            currentCoverage: 0,
            soundEnabled: true,
            hapticEnabled: true,
            reminderEnabled: false,
            reminderHour: 9,
            reminderMinute: 0,
            smartAlertEnabled: false,
            smartAlertDays: 3,
            instrumentTheme: InstrumentTheme.radar.rawValue,
            dismissedTips: []
        )
    }
}

enum MainTab: Int, CaseIterable, Identifiable {
    case sky
    case log
    case insights
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sky: return "Sky"
        case .log: return "Log"
        case .insights: return "Stats"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .sky: return "cloud.sun"
        case .log: return "list.bullet.rectangle"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}
