import Foundation
import Combine

final class SkyTrackerViewModel: ObservableObject {
    enum Segment: String, CaseIterable, Identifiable {
        case current
        case historical

        var id: String { rawValue }

        var title: String {
            switch self {
            case .current: return "Current"
            case .historical: return "Historical"
            }
        }
    }

    @Published var segment: Segment = .current
    @Published var draftCoverage: Double = 45
    @Published var draftNote: String = ""
    @Published var draftTags: [ConditionTag] = []
    @Published var draftLocation: String = ""
    @Published var draftPeriod: ObservationPeriod = ObservationPeriod.from(date: Date())

    func resetDraftMetadata() {
        draftNote = ""
        draftTags = []
        draftPeriod = ObservationPeriod.from(date: Date())
    }
}
