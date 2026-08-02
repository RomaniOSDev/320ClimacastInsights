import Foundation

struct CloudHistoryPoint: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var coverage: Double

    init(id: UUID = UUID(), date: Date = Date(), coverage: Double) {
        self.id = id
        self.date = date
        self.coverage = min(max(coverage, 0), 100)
    }
}
