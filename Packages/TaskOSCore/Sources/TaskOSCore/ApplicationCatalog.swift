import Foundation

public struct ApplicationRecord: Hashable, Sendable {
    public let bundleIdentifier: String
    public let displayName: String
    public let fileName: String
    public let url: URL?
    public let aliases: [String]

    public init(
        bundleIdentifier: String,
        displayName: String,
        fileName: String,
        url: URL? = nil,
        aliases: [String] = []
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.fileName = fileName
        self.url = url
        self.aliases = aliases
    }

    public var acceptedNames: [String] {
        [displayName, fileName] + aliases
    }

    public var resource: ApplicationResource {
        ApplicationResource(bundleIdentifier: bundleIdentifier, displayName: displayName)
    }

    public func matches(normalized name: String) -> Bool {
        acceptedNames.contains { ApplicationResolver.normalize($0) == name }
    }
}

public struct ApplicationSnapshot: Hashable, Sendable {
    public let revision: Int
    public let createdAt: Date
    public let applications: [ApplicationRecord]

    public init(revision: Int, createdAt: Date, applications: [ApplicationRecord]) {
        self.revision = revision
        self.createdAt = createdAt
        self.applications = applications
    }

    public static let empty = ApplicationSnapshot(revision: 0, createdAt: .distantPast, applications: [])

    public var isEmpty: Bool {
        applications.isEmpty
    }

    public var isOverCap: Bool {
        applications.count > CommandLimits.maximumApplications
    }
}

public enum ApplicationResolution: Hashable, Sendable {
    case resolved(ApplicationRecord)
    case missing
    case ambiguous([ApplicationRecord])
    case overCap
    case emptyCatalog
}

public enum ApplicationResolver {
    public static func normalize(_ name: String) -> String {
        var value = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if value.hasSuffix(".app") {
            value = String(value.dropLast(4))
        }
        return value
    }

    public static func resolve(_ name: String, in snapshot: ApplicationSnapshot) -> ApplicationResolution {
        if snapshot.applications.isEmpty {
            return .emptyCatalog
        }
        if snapshot.isOverCap {
            return .overCap
        }

        let query = normalize(name)
        guard !query.isEmpty else { return .missing }

        let matches = snapshot.applications.filter { $0.matches(normalized: query) }
        switch matches.count {
        case 0:
            return .missing
        case 1:
            return .resolved(matches[0])
        default:
            return .ambiguous(matches.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending })
        }
    }
}

public struct ApplicationGrouping: Hashable, Sendable {
    public let records: [ApplicationRecord]
    public let rewrites: [String]

    public init(records: [ApplicationRecord], rewrites: [String]) {
        self.records = records
        self.rewrites = rewrites
    }
}

public enum ApplicationGroupingResult: Hashable, Sendable {
    case single(ApplicationGrouping)
    case ambiguous([ApplicationGrouping])
    case unresolved([String])
    case overCap
    case emptyCatalog
}

public enum ApplicationListGrouper {
    public static func group(
        segments: [String],
        actionHead: String = "open",
        snapshot: ApplicationSnapshot,
        limit: Int = 2
    ) -> ApplicationGroupingResult {
        if snapshot.applications.isEmpty {
            return .emptyCatalog
        }
        if snapshot.isOverCap {
            return .overCap
        }

        let cleaned = segments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else {
            return .unresolved([])
        }

        var groupings: [ApplicationGrouping] = []
        var seen = Set<[String]>()
        var current: [ApplicationRecord] = []

        func candidate(_ range: ClosedRange<Int>) -> String {
            if range.lowerBound == range.upperBound {
                return cleaned[range.lowerBound]
            }
            return cleaned[range].joined(separator: " and ")
        }

        func search(_ index: Int) {
            if groupings.count >= limit {
                return
            }
            if index == cleaned.count {
                let key = current.map(\.bundleIdentifier)
                if seen.insert(key).inserted {
                    groupings.append(
                        ApplicationGrouping(records: current, rewrites: [rewrite(for: current, actionHead: actionHead)])
                    )
                }
                return
            }

            for end in index..<cleaned.count {
                let name = candidate(index...end)
                if case .resolved(let record) = ApplicationResolver.resolve(name, in: snapshot) {
                    current.append(record)
                    search(end + 1)
                    current.removeLast()
                    if groupings.count >= limit {
                        return
                    }
                }
            }
        }

        search(0)

        if groupings.isEmpty {
            return .unresolved(cleaned)
        }
        if groupings.count == 1 {
            return .single(groupings[0])
        }
        return .ambiguous(groupings)
    }

    public static func rewrite(for records: [ApplicationRecord], actionHead: String) -> String {
        let language = CommandLanguageCatalog.standard
        let head = actionHead.isEmpty
            ? "Open"
            : actionHead.prefix(1).uppercased() + actionHead.dropFirst()
        let names = records.map { language.applicationPhrase($0.displayName) }
        let phrases = names.enumerated().map { index, name in
            "\(index == 0 ? head : actionHead) \(name)"
        }
        return phrases.joined(separator: language.shared.actionJoiner)
    }
}
