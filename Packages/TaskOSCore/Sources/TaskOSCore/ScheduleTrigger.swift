import Foundation

public enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    public static let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    public static let weekend: Set<Weekday> = [.saturday, .sunday]
}

public enum ScheduleTrigger: Codable, Hashable, Sendable {
    public static let minimumInterval: TimeInterval = 15 * 60
    public static let maximumInterval: TimeInterval = 24 * 60 * 60

    case oneTime(Date)
    case daily(hour: Int, minute: Int)
    case weekdays(Set<Weekday>, hour: Int, minute: Int)
    case interval(every: TimeInterval, startingAt: Date)

    public var id: TriggerID { .schedule }

    public var followsWallClock: Bool {
        switch self {
        case .oneTime, .daily, .weekdays:
            return true
        case .interval:
            return false
        }
    }
}

extension ScheduleTrigger {
    public func validate() -> ValidationResult {
        validate(relativeTo: nil)
    }

    public func validate(relativeTo now: Date?) -> ValidationResult {
        var issues: [ValidationIssue] = []

        switch self {
        case .oneTime(let date):
            if let now, date < now {
                issues.append(.error("A one-time schedule must be in the future."))
            }
        case .daily(let hour, let minute):
            issues.append(contentsOf: Self.timeIssues(hour: hour, minute: minute))
        case .weekdays(let days, let hour, let minute):
            if days.isEmpty {
                issues.append(.error("Choose at least one weekday."))
            }
            issues.append(contentsOf: Self.timeIssues(hour: hour, minute: minute))
        case .interval(let every, _):
            if every < Self.minimumInterval || every > Self.maximumInterval {
                issues.append(.error("Interval must be between 15 minutes and 24 hours."))
            }
        }

        return ValidationResult(issues: issues)
    }

    public func isPastDue(relativeTo now: Date) -> Bool {
        guard case .oneTime(let date) = self else { return false }
        return date < now
    }

    private static func timeIssues(hour: Int, minute: Int) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if !(0...23).contains(hour) {
            issues.append(.error("Hour must be between 0 and 23."))
        }
        if !(0...59).contains(minute) {
            issues.append(.error("Minute must be between 0 and 59."))
        }
        return issues
    }
}

public struct ScheduleCalculator: Sendable {
    public static let defaultPreviewCount = 3
    public static let maximumPreviewCount = 10

    public var calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public init(timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
    }

    public func nextOccurrence(of schedule: ScheduleTrigger, after date: Date) -> Date? {
        nextOccurrences(of: schedule, after: date, count: 1).first
    }

    public func nextOccurrences(
        of schedule: ScheduleTrigger,
        after date: Date,
        count: Int = ScheduleCalculator.defaultPreviewCount
    ) -> [Date] {
        guard count > 0 else { return [] }

        switch schedule {
        case .oneTime(let scheduled):
            return scheduled > date ? [scheduled] : []
        case .daily(let hour, let minute):
            return wallClockOccurrences(after: date, count: count, hour: hour, minute: minute, weekdays: nil)
        case .weekdays(let days, let hour, let minute):
            guard !days.isEmpty else { return [] }
            return wallClockOccurrences(after: date, count: count, hour: hour, minute: minute, weekdays: days)
        case .interval(let every, let anchor):
            return intervalOccurrences(after: date, count: count, every: every, anchor: anchor)
        }
    }

    private func wallClockOccurrences(
        after date: Date,
        count: Int,
        hour: Int,
        minute: Int,
        weekdays: Set<Weekday>?
    ) -> [Date] {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return [] }

        var results: [Date] = []
        var dayStart = calendar.startOfDay(for: date)
        let components = DateComponents(hour: hour, minute: minute, second: 0)

        while results.count < count {
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }

            let eligible: Bool
            if let weekdays {
                let weekdayNumber = calendar.component(.weekday, from: dayStart)
                eligible = weekdays.contains(Weekday(rawValue: weekdayNumber) ?? .sunday)
            } else {
                eligible = true
            }

            if eligible,
               let candidate = calendar.nextDate(
                   after: dayStart.addingTimeInterval(-1),
                   matching: components,
                   matchingPolicy: .nextTime,
                   repeatedTimePolicy: .first,
                   direction: .forward
               ),
               candidate > date,
               candidate < dayEnd,
               matchesWallClock(candidate, hour: hour, minute: minute) {
                results.append(candidate)
            }

            dayStart = dayEnd
        }

        return results
    }

    private func matchesWallClock(_ date: Date, hour: Int, minute: Int) -> Bool {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return parts.hour == hour && parts.minute == minute
    }

    private func intervalOccurrences(
        after date: Date,
        count: Int,
        every: TimeInterval,
        anchor: Date
    ) -> [Date] {
        guard every > 0 else { return [] }

        var next: Date
        if date < anchor {
            next = anchor
        } else {
            let periods = (date.timeIntervalSince(anchor) / every).rounded(.down) + 1
            next = anchor.addingTimeInterval(periods * every)
        }

        var results: [Date] = []
        for _ in 0..<count {
            results.append(next)
            next = next.addingTimeInterval(every)
        }
        return results
    }
}
