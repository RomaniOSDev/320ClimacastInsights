import Foundation

enum ConditionTag: String, CaseIterable, Identifiable, Codable {
    case fog
    case rain
    case wind
    case haze

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fog: return "Fog"
        case .rain: return "Rain"
        case .wind: return "Wind"
        case .haze: return "Haze"
        }
    }

    var symbolName: String {
        switch self {
        case .fog: return "cloud.fog.fill"
        case .rain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .haze: return "sun.haze.fill"
        }
    }
}

enum ObservationPeriod: String, CaseIterable, Identifiable, Codable {
    case morning
    case noon
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .noon: return "Noon"
        case .evening: return "Evening"
        }
    }

    var symbolName: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }

    static func from(date: Date) -> ObservationPeriod {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .morning
        case 11..<17: return .noon
        default: return .evening
        }
    }
}

enum CoveragePreset: String, CaseIterable, Identifiable {
    case clear
    case partly
    case overcast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear: return "Clear"
        case .partly: return "Partly"
        case .overcast: return "Overcast"
        }
    }

    var coverage: Double {
        switch self {
        case .clear: return 10
        case .partly: return 45
        case .overcast: return 90
        }
    }

    var symbolName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partly: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        }
    }
}

enum InstrumentTheme: String, CaseIterable, Identifiable, Codable {
    case radar
    case dawn
    case arctic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .radar: return "Radar"
        case .dawn: return "Dawn"
        case .arctic: return "Arctic"
        }
    }

    var hueDegrees: Double {
        switch self {
        case .radar: return 0
        case .dawn: return 38
        case .arctic: return -28
        }
    }

    var detail: String {
        switch self {
        case .radar: return "Default instrument green"
        case .dawn: return "Warm amber scan"
        case .arctic: return "Cool blue scan"
        }
    }
}

enum CoachTip: String, CaseIterable, Identifiable {
    case firstLog
    case readCharts
    case usePresets
    case setReminder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstLog: return "First log saved"
        case .readCharts: return "Read your charts"
        case .usePresets: return "Use quick presets"
        case .setReminder: return "Stay on streak"
        }
    }

    var message: String {
        switch self {
        case .firstLog:
            return "Open Stats to see trends after a few more sky checks."
        case .readCharts:
            return "Distribution and weekly activity help spot cloudy patterns."
        case .usePresets:
            return "Tap Clear / Partly / Overcast for faster logging."
        case .setReminder:
            return "Enable a daily reminder in Settings to protect your streak."
        }
    }
}

struct PeriodComparison {
    let label: String
    let count: Int
    let average: Double
    let peak: Double

    static let empty = PeriodComparison(label: "", count: 0, average: 0, peak: 0)
}
