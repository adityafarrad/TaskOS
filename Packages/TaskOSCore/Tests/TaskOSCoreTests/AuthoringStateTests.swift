import Testing
import Foundation
@testable import TaskOSCore

@Suite("Authoring state and exact time")
struct AuthoringStateTests {
    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func tokyoCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func notificationMessages(_ document: ComposerDocument) -> [String] {
        document.actions.compactMap { action in
            if case .showNotification(_, let message) = action.draft {
                return message
            }
            return nil
        }
    }

    @Test func duplicateNotificationsKeepMessagesThroughUnrelatedEdit() {
        var document = ComposerDocument(text: "show a notification, then show a notification")
        let ids = document.actions.map(\.id)
        #expect(ids.count == 2)

        document.updateAction(id: ids[0], draft: .showNotification(title: "One", message: "first"))
        document.updateAction(id: ids[1], draft: .showNotification(title: "Two", message: "second"))

        document.setText("show a notification, then show a notification, then wait 1 second")

        #expect(notificationMessages(document) == ["first", "second"])
        #expect(Set(document.actions.map(\.id)).isSuperset(of: ids))
    }

    @Test func reorderingCardsMovesMessagesWithTheirNodes() {
        var document = ComposerDocument(text: "show a notification, then show a notification")
        let ids = document.actions.map(\.id)
        document.updateAction(id: ids[0], draft: .showNotification(title: "One", message: "first"))
        document.updateAction(id: ids[1], draft: .showNotification(title: "Two", message: "second"))

        document.moveActions(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        #expect(document.actions.map(\.id) == [ids[1], ids[0]])
        #expect(notificationMessages(document) == ["second", "first"])
    }

    @Test func deleteAndUndoRestoreTheMessage() {
        var document = ComposerDocument(text: "show a notification, then show a notification")
        let ids = document.actions.map(\.id)
        document.updateAction(id: ids[1], draft: .showNotification(title: "Two", message: "second"))

        document.removeAction(id: ids[1])
        #expect(notificationMessages(document) == [""])

        document.undo()
        #expect(notificationMessages(document) == ["", "second"])
    }

    @Test func insertingAThirdIdenticalClauseKeepsExistingMessages() {
        var document = ComposerDocument(text: "show a notification, then show a notification")
        let ids = document.actions.map(\.id)
        document.updateAction(id: ids[0], draft: .showNotification(title: "One", message: "first"))
        document.updateAction(id: ids[1], draft: .showNotification(title: "Two", message: "second"))

        document.addAction(.showNotification(title: "TaskOS", message: "third"))
        #expect(document.actions.count == 3)
        #expect(Set(ids).isSubset(of: Set(document.actions.map(\.id))))
        #expect(notificationMessages(document) == ["first", "second", "third"])
    }

    @Test func ambiguousDuplicateRemapClearsUncertainBindings() {
        var document = ComposerDocument(text: "show a notification, then show a notification")
        let ids = document.actions.map(\.id)
        document.updateAction(id: ids[0], draft: .showNotification(title: "One", message: "first"))
        document.updateAction(id: ids[1], draft: .showNotification(title: "Two", message: "second"))

        document.setText("show a notification, then show a notification, then show a notification")

        #expect(document.actions.count == 3)
        #expect(notificationMessages(document) == ["", "", ""])
    }

    @Test func structuredSnapshotRoundTripsCardValuesAndResolution() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var document = ComposerDocument(text: "in 45 minutes, then show a notification")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected a notification action")
            return
        }
        document.updateAction(id: id, draft: .showNotification(title: "Keep", message: "value"))
        document.resolveSchedule(now: base, calendar: utcCalendar())

        let snapshot = document.makeSnapshot()
        guard let restored = ComposerDocument(snapshot: snapshot) else {
            Issue.record("Expected the snapshot to restore")
            return
        }

        #expect(restored.trigger == document.trigger)
        #expect(restored.actions.map(\.id) == document.actions.map(\.id))
        #expect(notificationMessages(restored) == ["value"])
        #expect(restored.triggerConfiguration() == .schedule(.oneTime(base.addingTimeInterval(45 * 60))))
    }

    @Test func legacyDraftWithoutPayloadRestoresText() {
        let legacy = ComposerDraft(name: "Old", text: "show a notification", payload: nil)
        #expect(legacy.schemaVersion == 1)
        #expect(legacy.authoringSnapshot == nil)

        let document = ComposerDocument(text: legacy.text)
        #expect(document.actions.count == 1)
    }

    @Test func versionTwoDraftCarriesTheSnapshot() {
        var document = ComposerDocument(text: "show a notification")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected a notification action")
            return
        }
        document.updateAction(id: id, draft: .showNotification(title: "T", message: "carried"))

        let payload = ComposerDraft.encode(snapshot: document.makeSnapshot())
        let draft = ComposerDraft(name: "New", text: document.text, payload: payload)
        #expect(draft.schemaVersion == 2)
        #expect(draft.authoringSnapshot?.nodes.count == 1)

        let restored = ComposerDocument(snapshot: draft.authoringSnapshot!)!
        #expect(notificationMessages(restored) == ["carried"])
    }

    @Test func oneTimeScheduleResolvesOnce() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var document = ComposerDocument(text: "in 45 minutes, then show a notification")
        document.resolveSchedule(now: base, calendar: utcCalendar())

        let resolved = document.triggerConfiguration()
        #expect(resolved == .schedule(.oneTime(base.addingTimeInterval(45 * 60))))

        let later = document.makeDefinition(
            name: "Later",
            now: base.addingTimeInterval(600),
            calendar: utcCalendar()
        )
        #expect(later?.trigger == resolved)
    }

    @Test func unrelatedEditDoesNotMoveTheDateAndScheduleEditDoes() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var document = ComposerDocument(text: "in 45 minutes, then show a notification")
        document.resolveSchedule(now: base, calendar: utcCalendar())
        let first = document.triggerConfiguration()

        document.setText("in 45 minutes, then show a notification, then wait 1 second")
        #expect(document.triggerConfiguration() == first)

        document.setText("in 30 minutes, then show a notification, then wait 1 second")
        #expect(document.trigger == .relative(30 * 60))
        #expect(document.scheduleResolution.oneTimeDate == nil)

        document.resolveSchedule(now: base, calendar: utcCalendar())
        #expect(document.triggerConfiguration() == .schedule(.oneTime(base.addingTimeInterval(30 * 60))))
    }

    @Test func cardScheduleEditResolvesFresh() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var document = ComposerDocument()
        document.addAction(.showNotification(title: "T", message: ""))
        document.setTrigger(.once(hour: 19, minute: 0))
        #expect(document.scheduleResolution.oneTimeDate == nil)

        document.resolveSchedule(now: base, calendar: utcCalendar())
        #expect(document.scheduleResolution.oneTimeDate != nil)

        document.setTrigger(.once(hour: 20, minute: 0))
        #expect(document.scheduleResolution.oneTimeDate == nil)
    }

    @Test func timeZoneChangeKeepsTheStoredInstant() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var document = ComposerDocument(text: "in 45 minutes, then show a notification")
        document.resolveSchedule(now: base, calendar: utcCalendar())
        let stored = document.scheduleResolution.oneTimeDate

        document.resolveSchedule(now: base.addingTimeInterval(999), calendar: tokyoCalendar())
        #expect(document.scheduleResolution.oneTimeDate == stored)
        #expect(document.scheduleResolution.timeZoneIdentifier == "Asia/Tokyo")
    }

    @Test func openingASavedDefinitionPreservesExactDate() {
        let exact = Date(timeIntervalSince1970: 1_800_000_123)
        let definition = AutomationDefinition(
            id: AutomationID(),
            name: "Saved",
            revision: WorkflowRevision(1),
            trigger: .schedule(.oneTime(exact)),
            actions: [.showNotification(ShowNotificationAction(title: "T", message: "M"))]
        )

        let document = ComposerDocument(definition: definition)
        #expect(document.trigger == .oneTime(exact))
        #expect(document.scheduleResolution.oneTimeDate == exact)
        #expect(document.triggerConfiguration() == .schedule(.oneTime(exact)))
    }

    @Test func restoredSnapshotKeepsUnresolvedClauses() {
        var document = ComposerDocument(text: "open safari then open")
        document.resolveApplication(
            id: document.actions[0].id,
            reference: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )
        #expect(document.makeDefinition(name: "Live") == nil)

        guard let restored = ComposerDocument(snapshot: document.makeSnapshot()) else {
            Issue.record("Expected a restored snapshot")
            return
        }
        #expect(restored.unresolvedTexts.contains("open"))
        #expect(restored.makeDefinition(name: "Draft") == nil)
    }

    @Test func restoredSnapshotPreservesStructuredValues() {
        var document = ComposerDocument(text: "show a notification")
        document.updateAction(
            id: document.actions[0].id,
            draft: .showNotification(title: "T", message: "kept")
        )

        guard let restored = ComposerDocument(snapshot: document.makeSnapshot()) else {
            Issue.record("Expected a restored snapshot")
            return
        }
        if case .showNotification(let title, let message)? = restored.actions.first?.draft {
            #expect(title == "T")
            #expect(message == "kept")
        } else {
            Issue.record("Expected the notification to be restored")
        }
    }

    @Test func restoredSnapshotPreservesAnExactOneTimeDate() {
        let exact = Date(timeIntervalSince1970: 1_800_000_123)
        let document = ComposerDocument(trigger: .oneTime(exact), actions: [.wait(1)])

        guard let restored = ComposerDocument(snapshot: document.makeSnapshot()) else {
            Issue.record("Expected a restored snapshot")
            return
        }
        #expect(restored.trigger == .oneTime(exact))
        #expect(restored.scheduleResolution.oneTimeDate == exact)
    }

    @Test func authoringCalendarIsGregorian() {
        #expect(ComposerDocument.authoringCalendar.identifier == .gregorian)
    }

    @Test func relativeDaySchedulesResolveOnceToTheExactDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 10, minute: 0))!

        var document = ComposerDocument(text: "today at 11:00 pm open Notes")
        document.resolveApplication(
            id: document.actions[0].id,
            reference: .application(bundleIdentifier: "com.apple.Notes", label: "Notes")
        )
        let todayTarget = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 20, hour: 23, minute: 0)
        )!
        #expect(
            document.triggerConfiguration(relativeTo: now, calendar: calendar)
                == .schedule(.oneTime(todayTarget))
        )

        document.setText("tomorrow at 9:00 am open Notes")
        let tomorrowTarget = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 21, hour: 9, minute: 0)
        )!
        #expect(
            document.triggerConfiguration(relativeTo: now, calendar: calendar)
                == .schedule(.oneTime(tomorrowTarget))
        )

        let definition = document.makeDefinition(name: "Tomorrow", now: now, calendar: calendar)
        #expect(definition?.trigger == .schedule(.oneTime(tomorrowTarget)))
    }

    @Test func pastDueTodayScheduleBlocksDefinition() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 10, minute: 0))!

        var document = ComposerDocument(text: "today at 9:00 am open Notes")
        document.resolveApplication(
            id: document.actions[0].id,
            reference: .application(bundleIdentifier: "com.apple.Notes", label: "Notes")
        )
        #expect(document.makeDefinition(name: "Past", now: now, calendar: calendar) == nil)
    }
}
