import SwiftUI

struct InsightsView: View {
    @ObservedObject var store: AppDataStore
    @State private var showAddPast = false
    @State private var filterTag: ConditionTag?
    @State private var filterLocation: String = ""
    @State private var filterPeriod: ObservationPeriod?

    private var filteredEntries: [CloudLogEntry] {
        store.filteredLog(
            tag: filterTag,
            location: filterLocation.isEmpty ? nil : filterLocation,
            period: filterPeriod
        )
    }

    private var filteredHistory: [CloudHistoryPoint] {
        filteredEntries
            .map { CloudHistoryPoint(id: $0.id, date: $0.date, coverage: $0.coverage) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Text("STATS CHANNEL")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Spacer()
                        Text(String(format: "%02d", filteredEntries.count))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(Color("AppAccent"))
                    }

                    Image("bannerChart")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .opacity(0.4)
                        .clipped()
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                        }

                    if store.cloudLog.isEmpty {
                        EmptyStateView(
                            title: "Start tracking your clouds!",
                            systemImage: "sun.max",
                            secondarySystemImage: "cloud"
                        )
                    } else {
                        statsFilters

                        summaryGrid

                        periodCompareSection

                        timeOfDaySection

                        GlassPanel(accent: true) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("COVERAGE TREND // TRACE")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                CoverageLineChart(points: filteredHistory)
                            }
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DISTRIBUTION // BANDS")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Observations by cloud cover range")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                CoverageDistributionChart(entries: filteredEntries)
                            }
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ACTIVITY // LAST 7 DAYS")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Logs recorded each day")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                WeeklyActivityChart(entries: filteredEntries)
                            }
                        }

                        if !store.knownLocations.isEmpty {
                            locationBreakdown
                        }

                        GlassPanel(accent: true) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TELEMETRY // READOUT")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(Color("AppPrimary"))
                                telemetryLine(label: "Observations", value: "\(store.itemsCreated)")
                                telemetryLine(label: "Sessions", value: "\(store.sessionsCompleted)")
                                telemetryLine(label: "Streak", value: "\(store.streakDays)d")
                                telemetryLine(label: "Alert level", value: "\(Int(store.cloudAlertThreshold))%")
                                telemetryLine(
                                    label: "Above-threshold days",
                                    value: "\(store.consecutiveDaysAboveThreshold())"
                                )
                                telemetryLine(
                                    label: "Achievements",
                                    value: "\(store.achievementsUnlocked.count)/\(AchievementID.allCases.count)"
                                )
                            }
                        }
                    }

                    Button {
                        showAddPast = true
                    } label: {
                        Label {
                            Text("ADD PAST DATA")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1.4)
                        } icon: {
                            Image(systemName: "calendar.badge.plus")
                        }
                        .foregroundStyle(Color("AppBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BezelCTABackground())
                    }
                    .buttonStyle(.plain)

                    achievementsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .screenBackground()
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("STATISTICS // RADAR")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            .sheet(isPresented: $showAddPast) {
                AddPastDataSheet(store: store)
            }
        }
    }

    private var statsFilters: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("SLICE // FILTERS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppTextPrimary"))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(title: "All tags", selected: filterTag == nil) { filterTag = nil }
                        ForEach(ConditionTag.allCases) { tag in
                            FilterChip(title: tag.title, selected: filterTag == tag) { filterTag = tag }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(title: "Any time", selected: filterPeriod == nil) { filterPeriod = nil }
                        ForEach(ObservationPeriod.allCases) { period in
                            FilterChip(title: period.title, selected: filterPeriod == period) { filterPeriod = period }
                        }
                    }
                }

                if !store.knownLocations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterChip(title: "Any place", selected: filterLocation.isEmpty) { filterLocation = "" }
                            ForEach(store.knownLocations, id: \.self) { location in
                                FilterChip(title: location, selected: filterLocation == location) {
                                    filterLocation = location
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var summaryGrid: some View {
        let peak = filteredEntries.map(\.coverage).max() ?? 0
        let avg = filteredEntries.isEmpty ? 0 : filteredEntries.map(\.coverage).reduce(0, +) / Double(filteredEntries.count)
        let clearest = filteredEntries.min(by: { $0.coverage < $1.coverage })
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            insightCard(title: "Peak", value: "\(Int(peak))%", symbol: "arrow.up.right")
            insightCard(title: "Average", value: String(format: "%.0f%%", avg), symbol: "gauge.medium")
            insightCard(
                title: "Clearest",
                value: clearest.map { "\(Int($0.coverage))%" } ?? "—",
                symbol: "sun.max.fill"
            )
            insightCard(title: "Entries", value: "\(filteredEntries.count)", symbol: "cloud.fill")
        }
    }

    private var periodCompareSection: some View {
        let thisWeek = store.periodComparison(weeksAgo: 0)
        let lastWeek = store.periodComparison(weeksAgo: 1)
        return GlassPanel(accent: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text("PERIOD COMPARE // WEEKS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppTextPrimary"))
                HStack(spacing: 10) {
                    periodCard(thisWeek)
                    periodCard(lastWeek)
                }
                let delta = thisWeek.average - lastWeek.average
                Text(String(format: "AVG DELTA  %+.0f%%", delta))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(delta >= 0 ? Color("AppAccent") : Color("AppPrimary"))
            }
        }
    }

    private func periodCard(_ period: PeriodComparison) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(period.label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Color("AppTextSecondary"))
            Text(String(format: "%.0f%%", period.average))
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("AppTextPrimary"))
            Text("\(period.count) logs · peak \(Int(period.peak))%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
        )
    }

    private var timeOfDaySection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("TIME OF DAY // TRENDS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppTextPrimary"))
                ForEach(ObservationPeriod.allCases) { period in
                    let avg = store.averageCoverage(for: period)
                    let count = store.count(for: period)
                    HStack {
                        Image(systemName: period.symbolName)
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 18)
                        Text(period.title.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(Color("AppPrimary").opacity(0.85))
                                .frame(width: max(4, geo.size.width * CGFloat(avg / 100)))
                        }
                        .frame(height: 8)
                        Text(String(format: "%.0f%%/%d", avg, count))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color("AppAccent"))
                            .frame(width: 64, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var locationBreakdown: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("LOCATIONS // GROUPED")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppTextPrimary"))
                ForEach(store.knownLocations, id: \.self) { location in
                    let entries = store.cloudLog.filter { $0.location.caseInsensitiveCompare(location) == .orderedSame }
                    let avg = entries.map(\.coverage).reduce(0, +) / Double(max(entries.count, 1))
                    HStack {
                        Text(location.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Spacer()
                        Text("\(entries.count) · \(Int(avg))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
            }
        }
    }

    private func telemetryLine(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color("AppTextSecondary"))
            Text(String(repeating: "·", count: 18))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color("AppTextPrimary"))
        }
    }

    private func insightCard(title: String, value: String, symbol: String) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("AppPrimary"))
                    Spacer()
                }
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACHIEVEMENTS // STATUS")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Color("AppTextPrimary"))

            ForEach(AchievementID.allCases) { achievement in
                let unlocked = store.achievementsUnlocked.contains(achievement)
                GlassPanel(accent: unlocked) {
                    HStack(spacing: 12) {
                        Image(systemName: achievement.symbolName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                            .frame(width: 36, height: 36)
                            .overlay {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .stroke(
                                        (unlocked ? Color("AppPrimary") : Color("AppTextSecondary")).opacity(0.55),
                                        lineWidth: 1
                                    )
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(achievement.title.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text(achievement.detail)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Spacer()
                        Text(unlocked ? "ON" : "OFF")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                    }
                }
                .opacity(unlocked ? 1 : 0.72)
            }
        }
    }
}

struct AddPastDataSheet: View {
    @ObservedObject var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var coverage: Double = 40
    @State private var note = ""
    @State private var tags: [ConditionTag] = []
    @State private var location = ""
    @State private var period = ObservationPeriod.from(date: Date())

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .tint(Color("AppPrimary"))
                        .onChange(of: date) { newDate in
                            period = ObservationPeriod.from(date: newDate)
                        }
                    CoveragePresetRow(coverage: $coverage)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("COVERAGE \(Int(coverage))%")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Slider(value: $coverage, in: 0...100, step: 1)
                            .tint(Color("AppPrimary"))
                    }
                    ObservationPeriodPicker(period: $period)
                    ConditionTagPicker(tags: $tags)
                    LocationField(location: $location)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color("AppTextSecondary"))
                        TextField("Optional note", text: $note)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color("AppSurface").opacity(0.45))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                                    }
                            )
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .dismissKeyboardOnTap()
            .navigationTitle("Past data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addPastData(
                            coverage: coverage,
                            date: date,
                            note: note,
                            tags: tags,
                            location: location,
                            period: period
                        )
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }
}
