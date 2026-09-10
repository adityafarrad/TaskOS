import Foundation

public enum ResourceNameHeuristics {
    public static func isWebsite(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return false }

        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return true
        }

        let labels = trimmed.split(separator: ".")
        guard labels.count >= 2, let last = labels.last else { return false }
        return last.count >= 2 && last.allSatisfy { $0.isLetter }
    }

    public static func normalizedWebsiteURL(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
