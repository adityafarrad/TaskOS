import Testing
import Foundation
@testable import TaskOSCore

@Suite("TestClock")
struct ClockTests {
    @Test func startsAtProvidedInstant() {
        let start = Date(timeIntervalSince1970: 1_000)
        let clock = TestClock(now: start)
        #expect(clock.now() == start)
    }

    @Test func advanceMovesCurrentTime() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 0))
        clock.advance(by: .seconds(15))
        #expect(clock.now() == Date(timeIntervalSince1970: 15))
    }

    @Test func sleepResumesAfterAdvance() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let clock = TestClock(now: start)

        let task = Task { () -> Date in
            try await clock.sleep(for: .seconds(30))
            return clock.now()
        }

        await Task.yield()
        #expect(clock.now() == start)

        clock.advance(by: .seconds(30))
        let finished = try await task.value
        #expect(finished == start.addingTimeInterval(30))
    }
}
