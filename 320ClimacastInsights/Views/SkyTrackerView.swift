import SwiftUI

struct SkyTrackerView: View {
    @ObservedObject var store: AppDataStore
    @StateObject private var viewModel = SkyTrackerViewModel()
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Text("SCAN CHANNEL")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Spacer()
                        Text(String(format: "%05.1f", viewModel.draftCoverage))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(Color("AppAccent"))
                    }

                    Image("bannerCloud")
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

                    HorizonGraphic()

                    Picker("Segment", selection: $viewModel.segment) {
                        ForEach(SkyTrackerViewModel.Segment.allCases) { segment in
                            Text(segment.title.uppercased()).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 2)

                    if store.cloudLog.isEmpty && viewModel.segment == .historical {
                        EmptyStateView(title: "No history yet. Log a sky check to begin.", systemImage: "cloud.sun")
                    } else {
                        switch viewModel.segment {
                        case .current:
                            currentSection
                        case .historical:
                            historicalSection
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .dismissKeyboardOnTap()
            .navigationTitle("Sky")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CLOUD COVER // LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogObservationSheet(
                    store: store,
                    initialCoverage: viewModel.draftCoverage,
                    initialTags: viewModel.draftTags,
                    initialLocation: viewModel.draftLocation,
                    initialPeriod: viewModel.draftPeriod
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .openLogNow)) { _ in
                showLogSheet = true
            }
            .onAppear {
                if store.currentCoverage > 0 {
                    viewModel.draftCoverage = store.currentCoverage
                }
            }
        }
    }

    private var currentSection: some View {
        VStack(spacing: 12) {
            if store.cloudLog.isEmpty {
                EmptyStateView(
                    title: "No observations yet. Set coverage and log your first sky check.",
                    systemImage: "cloud.sun"
                )
            }

            GlassPanel(accent: true) {
                VStack(spacing: 14) {
                    CloudCoverageDial(coverage: viewModel.draftCoverage)
                        .frame(maxWidth: 280)
                        .frame(maxWidth: .infinity)

                    CoveragePresetRow(coverage: $viewModel.draftCoverage)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("OBSERVATION COVERAGE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Slider(value: $viewModel.draftCoverage, in: 0...100, step: 1)
                            .tint(Color("AppPrimary"))
                    }

                    ObservationPeriodPicker(period: $viewModel.draftPeriod)
                    ConditionTagPicker(tags: $viewModel.draftTags)
                    LocationField(location: $viewModel.draftLocation)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("ALERT THRESHOLD")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Spacer()
                            Text("\(Int(store.cloudAlertThreshold))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(Color("AppAccent"))
                        }
                        Slider(
                            value: Binding(
                                get: { store.cloudAlertThreshold },
                                set: { store.updateAlertThreshold($0) }
                            ),
                            in: 0...100,
                            step: 1
                        )
                        .tint(Color("AppAccent"))
                    }

                    Button {
                        store.logObservation(
                            coverage: viewModel.draftCoverage,
                            note: viewModel.draftNote,
                            tags: viewModel.draftTags,
                            location: viewModel.draftLocation,
                            period: viewModel.draftPeriod
                        )
                        viewModel.resetDraftMetadata()
                        HapticFeedback.success()
                    } label: {
                        Text("LOG CURRENT OBSERVATION")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color("AppBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(BezelCTABackground())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var historicalSection: some View {
        VStack(spacing: 10) {
            GlassPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("COVERAGE HISTORY // TRACE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color("AppTextPrimary"))
                    CoverageLineChart(points: store.sortedHistory)
                    Text("\(store.cloudDataHistory.count) RECORDED POINTS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }

            ForEach(store.sortedHistory.suffix(8).reversed()) { point in
                GlassPanel {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(point.date, style: .date)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text(point.date, style: .time)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Spacer()
                        Text("\(Int(point.coverage))%")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
        }
    }
}

struct LogObservationSheet: View {
    @ObservedObject var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State var coverage: Double
    @State private var note: String = ""
    @State private var tags: [ConditionTag]
    @State private var location: String
    @State private var period: ObservationPeriod

    init(
        store: AppDataStore,
        initialCoverage: Double,
        initialTags: [ConditionTag] = [],
        initialLocation: String = "",
        initialPeriod: ObservationPeriod = ObservationPeriod.from(date: Date())
    ) {
        self.store = store
        _coverage = State(initialValue: initialCoverage)
        _tags = State(initialValue: initialTags)
        _location = State(initialValue: initialLocation)
        _period = State(initialValue: initialPeriod)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("LOG NOW // CAPTURE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    CloudCoverageDial(coverage: coverage)
                        .frame(maxWidth: 240)
                        .frame(maxWidth: .infinity)

                    CoveragePresetRow(coverage: $coverage)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("COVERAGE")
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

                    Button {
                        store.logObservation(
                            coverage: coverage,
                            note: note,
                            tags: tags,
                            location: location,
                            period: period
                        )
                        dismiss()
                    } label: {
                        Text("SAVE OBSERVATION")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(Color("AppBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(BezelCTABackground())
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .dismissKeyboardOnTap()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
        }
    }
}
