import SwiftUI

struct CloudLogView: View {
    @ObservedObject var store: AppDataStore
    @State private var searchText = ""
    @State private var selectedTag: ConditionTag?
    @State private var selectedPeriod: ObservationPeriod?
    @State private var selectedLocation: String = ""
    @State private var minCoverage: Double = 0
    @State private var maxCoverage: Double = 100
    @State private var showFilters = false

    private var filteredEntries: [CloudLogEntry] {
        store.filteredLog(
            search: searchText,
            tag: selectedTag,
            location: selectedLocation.isEmpty ? nil : selectedLocation,
            period: selectedPeriod,
            minCoverage: minCoverage,
            maxCoverage: maxCoverage
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.cloudLog.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            telemetryTitle
                            EmptyStateView(
                                title: "Start logging your observations!",
                                systemImage: "cloud.fill"
                            )
                            .padding(.top, 40)
                        }
                        .padding(.horizontal, 16)
                    }
                } else {
                    VStack(spacing: 0) {
                        VStack(spacing: 10) {
                            telemetryTitle
                            searchField
                            if showFilters {
                                filtersPanel
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                        if filteredEntries.isEmpty {
                            EmptyStateView(
                                title: "No observations match your filters.",
                                systemImage: "line.3.horizontal.decrease.circle"
                            )
                            .padding(.top, 40)
                            Spacer()
                        } else {
                            List {
                                ForEach(filteredEntries) { entry in
                                    NavigationLink {
                                        LogDetailView(store: store, entry: entry)
                                    } label: {
                                        logRow(entry)
                                    }
                                    .listRowBackground(Color("AppBackground").opacity(0.55))
                                    .listRowSeparatorTint(Color("AppPrimary").opacity(0.2))
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        store.deleteLogEntry(filteredEntries[index])
                                    }
                                    HapticFeedback.soft()
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .dismissKeyboardOnTap()
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("OBSERVATION LOG // ARCHIVE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.cloudLog.isEmpty {
                        Button {
                            withAnimation { showFilters.toggle() }
                        } label: {
                            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundStyle(Color("AppAccent"))
                        }
                    }
                }
            }
        }
    }

    private var telemetryTitle: some View {
        HStack {
            Text("ARCHIVE BUFFER")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text("\(filteredEntries.count)/\(store.cloudLog.count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color("AppAccent"))
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color("AppTextSecondary"))
            TextField("Search note, place, cover…", text: $searchText)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color("AppSurface").opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                }
        )
    }

    private var filtersPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("FILTERS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color("AppPrimary"))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(title: "All tags", selected: selectedTag == nil) {
                            selectedTag = nil
                        }
                        ForEach(ConditionTag.allCases) { tag in
                            FilterChip(title: tag.title, selected: selectedTag == tag) {
                                selectedTag = tag
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(title: "Any time", selected: selectedPeriod == nil) {
                            selectedPeriod = nil
                        }
                        ForEach(ObservationPeriod.allCases) { period in
                            FilterChip(title: period.title, selected: selectedPeriod == period) {
                                selectedPeriod = period
                            }
                        }
                    }
                }

                if !store.knownLocations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterChip(title: "Any place", selected: selectedLocation.isEmpty) {
                                selectedLocation = ""
                            }
                            ForEach(store.knownLocations, id: \.self) { location in
                                FilterChip(title: location, selected: selectedLocation == location) {
                                    selectedLocation = location
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("COVER \(Int(minCoverage))–\(Int(maxCoverage))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppTextSecondary"))
                    HStack {
                        Text("MIN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Slider(value: $minCoverage, in: 0...maxCoverage, step: 1)
                            .tint(Color("AppPrimary"))
                    }
                    HStack {
                        Text("MAX")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Slider(value: $maxCoverage, in: minCoverage...100, step: 1)
                            .tint(Color("AppAccent"))
                    }
                }

                Button {
                    searchText = ""
                    selectedTag = nil
                    selectedPeriod = nil
                    selectedLocation = ""
                    minCoverage = 0
                    maxCoverage = 100
                } label: {
                    Text("RESET FILTERS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Color("AppAccent"))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func logRow(_ entry: CloudLogEntry) -> some View {
        HStack(spacing: 12) {
            Text(String(format: "%03d%%", Int(entry.coverage)))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 56, height: 36)
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.55), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(subtitle(for: entry))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
            }
            Spacer()
            Text(entry.period.title.prefix(1).uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("AppAccent"))
        }
        .padding(.vertical, 2)
    }

    private func subtitle(for entry: CloudLogEntry) -> String {
        var parts: [String] = []
        if !entry.location.isEmpty { parts.append(entry.location) }
        if !entry.tags.isEmpty { parts.append(entry.tags.map(\.title).joined(separator: "/")) }
        if !entry.note.isEmpty { parts.append(entry.note) }
        return (parts.isEmpty ? "No note" : parts.joined(separator: " · ")).uppercased()
    }
}

struct LogDetailView: View {
    @ObservedObject var store: AppDataStore
    let entry: CloudLogEntry
    @State private var showEdit = false

    private var liveEntry: CloudLogEntry {
        store.cloudLog.first(where: { $0.id == entry.id }) ?? entry
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("OBSERVATION // DETAIL")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                GlassPanel(accent: true) {
                    VStack(spacing: 14) {
                        CloudCoverageDial(coverage: liveEntry.coverage, animated: false)
                            .frame(maxWidth: 220)
                            .frame(maxWidth: .infinity)

                        detailRow(title: "Date", value: liveEntry.date.formatted(date: .long, time: .shortened))
                        detailRow(title: "Coverage", value: "\(Int(liveEntry.coverage))%")
                        detailRow(title: "Period", value: liveEntry.period.title)
                        detailRow(title: "Location", value: liveEntry.location.isEmpty ? "—" : liveEntry.location)
                        detailRow(
                            title: "Tags",
                            value: liveEntry.tags.isEmpty ? "—" : liveEntry.tags.map(\.title).joined(separator: ", ")
                        )
                        detailRow(title: "Note", value: liveEntry.note.isEmpty ? "—" : liveEntry.note)
                    }
                }

                Button {
                    showEdit = true
                } label: {
                    Text("EDIT OBSERVATION")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color("AppBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BezelCTABackground())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            EditLogEntrySheet(store: store, entry: liveEntry)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Color("AppTextSecondary"))
            Text(String(repeating: "·", count: 14))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EditLogEntrySheet: View {
    @ObservedObject var store: AppDataStore
    let entry: CloudLogEntry
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var coverage: Double
    @State private var note: String
    @State private var tags: [ConditionTag]
    @State private var location: String
    @State private var period: ObservationPeriod

    init(store: AppDataStore, entry: CloudLogEntry) {
        self.store = store
        self.entry = entry
        _date = State(initialValue: entry.date)
        _coverage = State(initialValue: entry.coverage)
        _note = State(initialValue: entry.note)
        _tags = State(initialValue: entry.tags)
        _location = State(initialValue: entry.location)
        _period = State(initialValue: entry.period)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CoveragePresetRow(coverage: $coverage)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("COVERAGE \(Int(coverage))%")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Slider(value: $coverage, in: 0...100, step: 1)
                            .tint(Color("AppPrimary"))
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .tint(Color("AppPrimary"))
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
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateLogEntry(
                            entry,
                            coverage: coverage,
                            note: note,
                            date: date,
                            tags: tags,
                            location: location,
                            period: period
                        )
                        HapticFeedback.success()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }
}
