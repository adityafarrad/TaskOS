import Foundation

public struct SourceSpan: Hashable, Sendable, Codable {
    public let start: Int
    public let end: Int

    public init(start: Int, end: Int) {
        let clampedStart = max(0, start)
        self.start = clampedStart
        self.end = max(clampedStart, end)
    }

    public var length: Int {
        end - start
    }

    public func isValid(in text: String) -> Bool {
        start >= 0 && end >= start && end <= text.utf16.count
    }

    public func range(in text: String) -> Range<String.Index>? {
        guard isValid(in: text) else {
            return nil
        }
        let utf16 = text.utf16
        guard let startUTF16 = utf16.index(utf16.startIndex, offsetBy: start, limitedBy: utf16.endIndex),
              let endUTF16 = utf16.index(utf16.startIndex, offsetBy: end, limitedBy: utf16.endIndex),
              let lower = String.Index(startUTF16, within: text),
              let upper = String.Index(endUTF16, within: text) else {
            return nil
        }
        return lower..<upper
    }
}

extension String {
    public func substring(in span: SourceSpan) -> String? {
        guard let range = span.range(in: self) else {
            return nil
        }
        return String(self[range])
    }
}
