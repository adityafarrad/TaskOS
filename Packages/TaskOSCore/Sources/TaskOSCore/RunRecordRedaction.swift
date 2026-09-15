import Foundation

public enum RunRecordRedaction {
    public static let maximumMessageLength = 300

    public static func sanitize(_ record: RunRecord) -> RunRecord {
        let actions = record.actions.map { item -> ActionRunRecord in
            guard case .failed(let failure) = item.outcome else { return item }
            let message = sanitize(message: failure.message)
            guard message != failure.message else { return item }
            return ActionRunRecord(
                index: item.index,
                actionID: item.actionID,
                outcome: .failed(ActionFailure(message: message, isTimedOut: failure.isTimedOut)),
                duration: item.duration
            )
        }
        return RunRecord(
            id: record.id,
            automationID: record.automationID,
            revision: record.revision,
            automationName: record.automationName,
            status: record.status,
            startedAt: record.startedAt,
            finishedAt: record.finishedAt,
            actions: actions
        )
    }

    public static func sanitize(message: String) -> String {
        var result = redactSensitiveRuns(in: message)
        if result.count > maximumMessageLength {
            result = String(result.prefix(maximumMessageLength)) + "…"
        }
        return result
    }

    private static func redactSensitiveRuns(in message: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: "(?:https?|file)://\\S+|/Users/\\S+",
            options: [.caseInsensitive]
        ) else {
            return message
        }
        let range = NSRange(message.startIndex..., in: message)
        return regex.stringByReplacingMatches(in: message, options: [], range: range, withTemplate: "[redacted]")
    }
}
