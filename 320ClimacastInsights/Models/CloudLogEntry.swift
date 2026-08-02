import Foundation

struct CloudLogEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var coverage: Double
    var note: String
    var tags: [ConditionTag]
    var location: String
    var period: ObservationPeriod

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        coverage: Double,
        note: String = "",
        tags: [ConditionTag] = [],
        location: String = "",
        period: ObservationPeriod? = nil
    ) {
        self.id = id
        self.date = date
        self.coverage = min(max(coverage, 0), 100)
        self.note = note
        self.tags = tags
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.period = period ?? ObservationPeriod.from(date: date)
    }

    enum CodingKeys: String, CodingKey {
        case id, date, coverage, note, tags, location, period
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        coverage = min(max(try c.decodeIfPresent(Double.self, forKey: .coverage) ?? 0, 0), 100)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        tags = try c.decodeIfPresent([ConditionTag].self, forKey: .tags) ?? []
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        period = try c.decodeIfPresent(ObservationPeriod.self, forKey: .period) ?? ObservationPeriod.from(date: date)
    }
}
