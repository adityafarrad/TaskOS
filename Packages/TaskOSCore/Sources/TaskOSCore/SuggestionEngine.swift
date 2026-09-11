import Foundation

public struct SuggestionEngine: Sendable {
    private let registry: CapabilityRegistry
    public let limit: Int

    public init(registry: CapabilityRegistry = .standard, limit: Int = 8) {
        self.registry = registry
        self.limit = limit
    }

    public func suggestions(
        for text: String,
        applications: [ApplicationResource] = []
    ) -> [Suggestion] {
        switch context(for: text) {
        case .start:
            return rankAndLimit(starters())

        case .openApplication(let prefix):
            let matches = applicationSuggestions(applications, prefix: prefix)
            if prefix.isEmpty {
                return rankAndLimit(starters(openOnly: true) + matches)
            }
            if matches.isEmpty {
                return rankAndLimit(starters(openOnly: true))
            }
            return rankAndLimit(matches)

        case .waitDuration:
            return rankAndLimit(waitSuggestions())

        case .notification:
            return rankAndLimit(notificationSuggestions())

        case .other:
            return []
        }
    }

    private enum SuggestionContext {
        case start
        case openApplication(prefix: String)
        case waitDuration
        case notification
        case other
    }

    private func context(for text: String) -> SuggestionContext {
        let fragment = trailingFragment(text).trimmingCharacters(in: .whitespacesAndNewlines)
        if fragment.isEmpty {
            return .start
        }

        let words = fragment.lowercased().split(separator: " ").map(String.init)
        guard let first = words.first else { return .start }

        switch first {
        case "open":
            return .openApplication(prefix: words.dropFirst().joined(separator: " "))
        case "wait":
            if words.count == 1 { return .waitDuration }
            if words.count == 2, words[1] == "for" { return .waitDuration }
            return .other
        case "show":
            if words.count == 1 { return .notification }
            if words.count == 2, words[1] == "a" || words[1] == "the" { return .notification }
            return .other
        case "notify":
            return .other
        default:
            return .other
        }
    }

    private func trailingFragment(_ text: String) -> String {
        let tokens = CommandTokenizer.tokenize(text)
        var start = 0
        for token in tokens where isConnector(token) {
            start = token.span.end
        }
        return text.substring(in: SourceSpan(start: start, end: text.count)) ?? text
    }

    private func isConnector(_ token: CommandToken) -> Bool {
        switch token.kind {
        case .word(let word):
            return word == "and" || word == "then" || word == "also"
        case .punctuation(let punctuation):
            return punctuation == ","
        case .number:
            return false
        }
    }

    private func starters(openOnly: Bool = false) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        suggestions.append(
            Suggestion(
                id: "action.openApplication",
                phrase: "Open an application",
                title: "Open an application",
                category: .action,
                requiresParameter: true,
                match: .grammarPosition
            )
        )

        suggestions.append(
            Suggestion(
                id: "action.openWebsite",
                phrase: "Open https://",
                title: "Open a website",
                category: .action,
                requiresParameter: true,
                match: .grammarPosition
            )
        )

        if !openOnly {
            suggestions.append(
                Suggestion(
                    id: "action.arrangeWindow",
                    phrase: "Put an application on the left half",
                    title: "Arrange a window",
                    category: .action,
                    requiresParameter: true,
                    match: .grammarPosition
                )
            )
            suggestions.append(
                Suggestion(
                    id: "action.wait",
                    phrase: "Wait 5 seconds",
                    title: "Wait",
                    category: .action,
                    requiresParameter: true,
                    match: .grammarPosition
                )
            )
            suggestions.append(
                Suggestion(
                    id: "action.showNotification",
                    phrase: "Show a notification",
                    title: "Show a notification",
                    category: .action,
                    requiresParameter: false,
                    match: .grammarPosition
                )
            )
            suggestions.append(
                Suggestion(
                    id: "action.copyText",
                    phrase: "Copy \"text\"",
                    title: "Copy text",
                    category: .action,
                    requiresParameter: true,
                    match: .grammarPosition
                )
            )
        }

        return suggestions
    }

    private func applicationSuggestions(_ applications: [ApplicationResource], prefix: String) -> [Suggestion] {
        let needle = prefix.lowercased()
        var results: [Suggestion] = []

        for application in applications {
            let label = application.displayName
            let haystack = label.lowercased()

            let match: SuggestionMatch?
            if needle.isEmpty {
                match = .prefix
            } else if haystack == needle {
                match = .exact
            } else if haystack.hasPrefix(needle) {
                match = .prefix
            } else if needle.count >= 3, levenshtein(haystack, needle) <= 2 {
                match = .typo
            } else {
                match = nil
            }

            guard let match else { continue }

            results.append(
                Suggestion(
                    id: "app.\(application.bundleIdentifier)",
                    phrase: "Open \(label)",
                    title: label,
                    category: .application,
                    requiresParameter: false,
                    match: match
                )
            )
        }

        return results
    }

    private func waitSuggestions() -> [Suggestion] {
        [
            Suggestion(
                id: "param.wait.1",
                phrase: "Wait 1 second",
                title: "Wait 1 second",
                category: .parameter,
                requiresParameter: false,
                match: .grammarPosition
            ),
            Suggestion(
                id: "param.wait.5",
                phrase: "Wait 5 seconds",
                title: "Wait 5 seconds",
                category: .parameter,
                requiresParameter: false,
                match: .grammarPosition
            ),
            Suggestion(
                id: "param.wait.30",
                phrase: "Wait 30 seconds",
                title: "Wait 30 seconds",
                category: .parameter,
                requiresParameter: false,
                match: .grammarPosition
            ),
        ]
    }

    private func notificationSuggestions() -> [Suggestion] {
        [
            Suggestion(
                id: "param.notification",
                phrase: "Show a notification",
                title: "Show a notification",
                category: .parameter,
                requiresParameter: false,
                match: .grammarPosition
            )
        ]
    }

    private func rankAndLimit(_ suggestions: [Suggestion]) -> [Suggestion] {
        let sorted = suggestions.sorted { lhs, rhs in
            let leftRank = Self.rank(lhs.match)
            let rightRank = Self.rank(rhs.match)
            if leftRank != rightRank {
                return leftRank < rightRank
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        var seen = Set<String>()
        var unique: [Suggestion] = []
        for suggestion in sorted where seen.insert(suggestion.id).inserted {
            unique.append(suggestion)
        }

        return Array(unique.prefix(limit))
    }

    private static func rank(_ match: SuggestionMatch) -> Int {
        switch match {
        case .grammarPosition: return 0
        case .exact: return 1
        case .prefix: return 2
        case .alias: return 3
        case .typo: return 4
        }
    }

    private func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)

        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0...right.count)
        var current = Array(repeating: 0, count: right.count + 1)

        for i in 1...left.count {
            current[0] = i
            for j in 1...right.count {
                let cost = left[i - 1] == right[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            previous = current
        }

        return previous[right.count]
    }
}
