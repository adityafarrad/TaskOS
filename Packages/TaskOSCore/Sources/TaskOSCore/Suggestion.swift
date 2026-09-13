import Foundation

public enum SuggestionMatch: String, Hashable, Sendable {
    case grammarPosition
    case exact
    case prefix
    case alias
    case typo
}

public struct Suggestion: Hashable, Sendable {
    public enum Category: String, Hashable, Sendable {
        case action
        case application
        case parameter
        case trigger
    }

    public let id: String
    public let phrase: String
    public let title: String
    public let category: Category
    public let requiresParameter: Bool
    public let match: SuggestionMatch

    public init(
        id: String,
        phrase: String,
        title: String,
        category: Category,
        requiresParameter: Bool,
        match: SuggestionMatch
    ) {
        self.id = id
        self.phrase = phrase
        self.title = title
        self.category = category
        self.requiresParameter = requiresParameter
        self.match = match
    }

    public var replacementMeaning: String {
        "replaces the current word with \(phrase)"
    }

    public var kind: SuggestionMatch {
        match
    }
}
