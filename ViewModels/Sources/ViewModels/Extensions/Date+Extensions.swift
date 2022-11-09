// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension Date {
    var timeAgo: String? {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        if
            let oneMinuteAgo = calendar.date(byAdding: DateComponents(minute: -1), to: now),
            oneMinuteAgo < self {
            Self.abbreviatedDateComponentsFormatter.allowedUnits = [.second]
        } else if
            let oneHourAgo = calendar.date(byAdding: DateComponents(hour: -1), to: now),
            oneHourAgo < self {
            Self.abbreviatedDateComponentsFormatter.allowedUnits = [.minute]
        } else if
            let oneDayAgo = calendar.date(byAdding: DateComponents(day: -1), to: now),
            oneDayAgo < self {
            Self.abbreviatedDateComponentsFormatter.allowedUnits = [.hour]
        } else if
            let oneWeekAgo = calendar.date(byAdding: DateComponents(weekOfMonth: -1), to: now),
            oneWeekAgo < self {
            Self.abbreviatedDateComponentsFormatter.allowedUnits = [.day]
        } else {
            return Date.shortDateStyleRelativeDateFormatter.string(from: self)
        }

        return Self.abbreviatedDateComponentsFormatter.string(from: self, to: now)
    }

    var accessibilityTimeAgo: String? {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        if
            let oneWeekAgo = calendar.date(byAdding: DateComponents(weekOfMonth: -1), to: now),
            oneWeekAgo < self {
            return Self.relativeTimeFormatter.localizedString(for: self, relativeTo: Date())
        }

        return Self.accessibilityFullDateComponentsFormatter.string(from: self)
    }

    var fullUnitTimeUntil: String? {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        if
            let oneDayFromNow = calendar.date(byAdding: DateComponents(day: 1), to: now),
            self > oneDayFromNow {
            Self.fullDateComponentsFormatter.allowedUnits = [.day]
        } else if
            let oneHourFromNow = calendar.date(byAdding: DateComponents(hour: 1), to: now),
            self > oneHourFromNow {
            Self.fullDateComponentsFormatter.allowedUnits = [.hour]
        } else if
            let oneMinuteFromNow = calendar.date(byAdding: DateComponents(minute: 1), to: now),
            self > oneMinuteFromNow {
            Self.fullDateComponentsFormatter.allowedUnits = [.minute]
        } else {
            Self.fullDateComponentsFormatter.allowedUnits = [.second]
        }

        return Self.fullDateComponentsFormatter.string(from: now, to: self)
    }
}

private extension Date {
    private static let abbreviatedDateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()

        dateComponentsFormatter.unitsStyle = .abbreviated

        return dateComponentsFormatter
    }()

    private static let fullDateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()

        dateComponentsFormatter.unitsStyle = .full

        return dateComponentsFormatter
    }()

    private static let shortDateStyleRelativeDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short

        return dateFormatter
    }()

    private static let relativeTimeFormatter: RelativeDateTimeFormatter = {
        let dateFormatter = RelativeDateTimeFormatter()

        dateFormatter.unitsStyle = .full

        return dateFormatter
    }()

    private static let accessibilityFullDateComponentsFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .long

        return dateFormatter
    }()
}
