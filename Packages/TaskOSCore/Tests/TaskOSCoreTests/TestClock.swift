import Foundation
import TaskOSCore

final class TestClock: CoreClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private var waiters: [UUID: (deadline: Date, continuation: CheckedContinuation<Void, Error>)] = [:]

    init(now: Date = Date(timeIntervalSince1970: 0)) {
        self.current = now
    }

    func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    var waiterCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return waiters.count
    }

    func sleep(for duration: Duration) async throws {
        let deadline = now().addingTimeInterval(duration.timeInterval)
        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lock.lock()
                if deadline <= current {
                    lock.unlock()
                    continuation.resume()
                    return
                }
                if Task.isCancelled {
                    lock.unlock()
                    continuation.resume(throwing: CancellationError())
                    return
                }
                waiters[id] = (deadline, continuation)
                lock.unlock()
            }
        } onCancel: {
            let waiter: CheckedContinuation<Void, Error>?
            lock.lock()
            waiter = waiters.removeValue(forKey: id)?.continuation
            lock.unlock()
            waiter?.resume(throwing: CancellationError())
        }
    }

    func advance(by duration: Duration) {
        let target = now().addingTimeInterval(duration.timeInterval)

        lock.lock()
        current = target
        let ready = waiters.filter { $0.value.deadline <= target }
        for key in ready.keys {
            waiters.removeValue(forKey: key)
        }
        lock.unlock()

        for waiter in ready.values {
            waiter.continuation.resume()
        }
    }
}
