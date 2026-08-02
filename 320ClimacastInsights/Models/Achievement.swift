import Foundation

enum AchievementID: String, Codable, CaseIterable, Identifiable {
    case firstCheck
    case alertSetup
    case regularObserver
    case skyWatcher
    case clearChoice
    case persistentTracker
    case cloudEnthusiast
    case insightSeeker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstCheck: return "First Check"
        case .alertSetup: return "Alert Setup"
        case .regularObserver: return "Regular Observer"
        case .skyWatcher: return "Sky Watcher"
        case .clearChoice: return "\"Clear\" Choice"
        case .persistentTracker: return "Persistent Tracker"
        case .cloudEnthusiast: return "Cloud Enthusiast"
        case .insightSeeker: return "Insight Seeker"
        }
    }

    var detail: String {
        switch self {
        case .firstCheck: return "Log your first cloud observation"
        case .alertSetup: return "Reach five logged observations"
        case .regularObserver: return "Keep a 7-day observation streak"
        case .skyWatcher: return "Complete 10 sky sessions"
        case .clearChoice: return "Log three cloud observations"
        case .persistentTracker: return "Keep a 30-day observation streak"
        case .cloudEnthusiast: return "Log 50 cloud observations"
        case .insightSeeker: return "Complete 14 sky sessions"
        }
    }

    var symbolName: String {
        switch self {
        case .firstCheck: return "cloud.sun.fill"
        case .alertSetup: return "bell.badge.fill"
        case .regularObserver: return "calendar"
        case .skyWatcher: return "eye.fill"
        case .clearChoice: return "sun.max.fill"
        case .persistentTracker: return "flame.fill"
        case .cloudEnthusiast: return "cloud.fill"
        case .insightSeeker: return "chart.line.uptrend.xyaxis"
        }
    }
}
