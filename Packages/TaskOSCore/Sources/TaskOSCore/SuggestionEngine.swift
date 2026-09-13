import Foundation

public struct SuggestionEngine: Sendable {
    private let registry: CapabilityRegistry
    private let language: CommandLanguageCatalog
    public let limit: Int

    public init(
        registry: CapabilityRegistry = .standard,
        language: CommandLanguageCatalog = .standard,
        limit: Int = 8
    ) {
        self.registry = registry
        self.language = language
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

            if prefix.contains("."), ResourceNameHeuristics.isWebsite(prefix) {
                let normalized = ResourceNameHeuristics.normalizedWebsiteURL(prefix)
                let website = Suggestion(
                    id: "website.\(normalized)",
                    phrase: language.websitePhrase(url: normalized),
                    title: normalized,
                    category: .parameter,
                    requiresParameter: false,
                    match: .exact
                )
                return rankAndLimit([website] + matches)
            }

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

        case .when:
            return rankAndLimit(whenSuggestions())

        case .other:
            return []
        }
    }

    private enum SuggestionContext {
        case start
        case openApplication(prefix: String)
        case waitDuration
        case notification
        case when
        case other
    }

    private func context(for text: String) -> SuggestionContext {
        let fragment = trailingFragment(text).trimmingCharacters(in: .whitespacesAndNewlines)
        if fragment.isEmpty {
            return .start
        }

        let words = fragment.lowercased().split(separator: " ").map(String.init)
        guard let first = words.first else { return .start }
        guard let route = language.clauseRoutes[first] else { return .other }

        switch route {
        case .open:
            return .openApplication(prefix: words.dropFirst().joined(separator: " "))
        case .wait:
            if words.count == 1 { return .waitDuration }
            if words.count == 2, language.wait.optionalWords.contains(words[1]) { return .waitDuration }
            return .other
        case .notification:
            if language.notification.directWords.contains(first) { return .other }
            if words.count == 1 { return .notification }
            if words.count == 2, language.notification.articles.contains(words[1]) { return .notification }
            return .other
        case .when:
            return .when
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
        return text.substring(in: SourceSpan(start: start, end: text.utf16.count)) ?? text
    }

    private func isConnector(_ token: CommandToken) -> Bool {
        switch token.kind {
        case .word(let word):
            return language.shared.connectorWords.contains(word)
        case .punctuation(let punctuation):
            return language.shared.connectorPunctuation.contains(punctuation)
        case .number:
            return false
        }
    }

    private func starters(openOnly: Bool = false) -> [Suggestion] {
        let openCapabilities: Set<ActionID> = [.openApplication, .openWebsite]
        return ActionID.allCases.compactMap { id in
            guard let starter = language.actionStarter(id) else { return nil }
            if openOnly, !openCapabilities.contains(id) { return nil }
            return suggestion(from: starter)
        }
    }

    private func applicationSuggestions(_ applications: [ApplicationResource], prefix: String) -> [Suggestion] {
        let needle = prefix.lowercased()
        var results: [Suggestion] = []

        for application in applications.prefix(CommandLimits.maximumApplications) {
            let label = application.displayName
            let haystack = label.lowercased()

            let match: SuggestionMatch?
            if needle.isEmpty {
                match = .prefix
            } else if haystack == needle {
                match = .exact
            } else if haystack.hasPrefix(needle) {
                match = .prefix
            } else if typoMatches(haystack, needle) {
                match = .typo
            } else {
                match = nil
            }

            guard let match else { continue }

            results.append(
                Suggestion(
                    id: "app.\(application.bundleIdentifier)",
                    phrase: language.canonicalActionTemplate(.openApplication)?
                        .render(["application": language.applicationPhrase(label)]) ?? "Open \(label)",
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
        language.waitStarters.map { suggestion(from: $0) }
    }

    private func notificationSuggestions() -> [Suggestion] {
        [suggestion(from: language.notificationStarter)]
    }

    private func whenSuggestions() -> [Suggestion] {
        language.whenStarters().map { suggestion(from: $0) }
    }

    private func suggestion(from starter: CommandLanguageCatalog.CompletionStarter) -> Suggestion {
        Suggestion(
            id: starter.id,
            phrase: starter.phrase,
            title: starter.title,
            category: starter.category,
            requiresParameter: starter.requiresParameter,
            match: .grammarPosition
        )
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
        var typoCount = 0
        for suggestion in sorted where seen.insert(suggestion.id).inserted {
            if suggestion.match == .typo {
                guard typoCount < 3 else { continue }
                typoCount += 1
            }
            unique.append(suggestion)
        }

        return Array(unique.prefix(limit))
    }

    private func typoMatches(_ haystack: String, _ needle: String) -> Bool {
        let length = needle.count
        guard length >= 5, length <= 64 else { return false }

        let distance = levenshtein(haystack, needle)
        if length <= 8 {
            return distance <= 1
        }

        let longest = max(haystack.count, length)
        guard longest > 0 else { return false }
        let normalized = Double(distance) / Double(longest)
        return distance <= 2 && normalized <= 0.20
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
