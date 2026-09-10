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
}

extension String {
    public func substring(in span: SourceSpan) -> String? {
        guard span.start <= span.end, span.end <= count else {
            return nil
        }
        let lower = index(startIndex, offsetBy: span.start)
        let upper = index(startIndex, offsetBy: span.end)
        return String(self[lower..<upper])
    }
}
