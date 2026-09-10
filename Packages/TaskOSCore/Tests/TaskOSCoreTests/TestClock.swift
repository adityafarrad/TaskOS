import Foundation
import TaskOSCore

final class TestClock: CoreClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private var waiters: [(deadline: Date, continuation: CheckedContinuation<Void, Error>)] = []

    init(now: Date = Date(timeIntervalSince1970: 0)) {
        self.current = now
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func sleep(for duration: Duration) async throws {
        let deadline = now().addingTimeInterval(duration.timeInterval)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lock.lock()
            if deadline <= current {
                lock.unlock()
                continuation.resume()
                return
            }
            waiters.append((deadline, continuation))
            lock.unlock()
        }
    }

    func advance(by duration: Duration) {
        let target = now().addingTimeInterval(duration.timeInterval)
        lock.lock()
        current = target
        let ready = waiters.filter { $0.deadline <= target }
        waiters.removeAll { $0.deadline <= target }
        lock.unlock()
        for waiter in ready {
            waiter.continuation.resume()
        }
    }
}
