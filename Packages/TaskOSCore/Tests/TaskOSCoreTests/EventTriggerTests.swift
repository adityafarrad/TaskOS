import Testing
import Foundation
import TaskOSCore

@Suite("Event triggers")
struct EventTriggerTests {
    private let safari = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")

    @Test func triggerIDsAndRegistryAreConsistent() {
        for id in TriggerID.allCases {
            #expect(CapabilityRegistry.standard.descriptor(for: id) != nil)
        }
        #expect(CapabilityRegistry.standard.consistencyIssues().isEmpty)
    }

    @Test func applicationLifecycleRequiresAnApplication() {
        #expect(ApplicationLifecycleTrigger(application: safari, event: .launched).trigger.validate().isValid)
        let unresolved = ApplicationLifecycleTrigger(
            application: .application(bundleIdentifier: "", label: ""),
            event: .quit
        )
        #expect(!unresolved.trigger.validate().isValid)
    }

    @Test func batteryThresholdBounds() {
        #expect(BatteryThresholdTrigger(comparator: .below, percentage: 20).trigger.validate().isValid)
        #expect(!BatteryThresholdTrigger(comparator: .below, percentage: 0).trigger.validate().isValid)
        #expect(!BatteryThresholdTrigger(comparator: .above, percentage: 100).trigger.validate().isValid)
    }

    @Test func matchesApplicationLaunchAndQuit() {
        let launch = ApplicationLifecycleTrigger(application: safari, event: .launched).trigger
        #expect(launch.matches(.applicationLaunched(bundleIdentifier: "com.apple.Safari")))
        #expect(!launch.matches(.applicationQuit(bundleIdentifier: "com.apple.Safari")))
        #expect(!launch.matches(.applicationLaunched(bundleIdentifier: "com.apple.Notes")))

        let quit = ApplicationLifecycleTrigger(application: safari, event: .quit).trigger
        #expect(quit.matches(.applicationQuit(bundleIdentifier: "com.apple.Safari")))
    }

    @Test func matchesWake() {
        #expect(WakeTrigger().trigger.matches(.woke))
        #expect(!WakeTrigger().trigger.matches(.powerSourceChanged(isOnExternalPower: true)))
    }

    @Test func matchesDisplaySelection() {
        let anyExternal = DisplayConnectionTrigger(selection: .anyExternal, event: .connected).trigger
        #expect(anyExternal.matches(.displayConnected(identifier: "123", isExternal: true)))
        #expect(!anyExternal.matches(.displayConnected(identifier: "builtin", isExternal: false)))
        #expect(!anyExternal.matches(.displayDisconnected(identifier: "123", isExternal: true)))

        let specific = DisplayConnectionTrigger(
            selection: .display(identifier: "123", label: "Studio Display"),
            event: .disconnected
        ).trigger
        #expect(specific.matches(.displayDisconnected(identifier: "123", isExternal: true)))
        #expect(!specific.matches(.displayDisconnected(identifier: "999", isExternal: true)))
        #expect(!specific.matches(.displayConnected(identifier: "123", isExternal: true)))
    }

    @Test func matchesVolumeSelection() {
        let anyExternal = ExternalVolumeTrigger(selection: .anyExternal, event: .mounted).trigger
        #expect(anyExternal.matches(.volumeMounted(identifier: "disk4s1", isExternal: true)))
        #expect(!anyExternal.matches(.volumeMounted(identifier: "disk0s1", isExternal: false)))

        let specific = ExternalVolumeTrigger(
            selection: .volume(identifier: "disk4s1", label: "Backup"),
            event: .unmounted
        ).trigger
        #expect(specific.matches(.volumeUnmounted(identifier: "disk4s1", isExternal: true)))
        #expect(!specific.matches(.volumeUnmounted(identifier: "disk5s1", isExternal: true)))
    }

    @Test func matchesPowerTransitions() {
        let toPower = PowerSourceTrigger(event: .toExternalPower).trigger
        #expect(toPower.matches(.powerSourceChanged(isOnExternalPower: true)))
        #expect(!toPower.matches(.powerSourceChanged(isOnExternalPower: false)))

        let toBattery = PowerSourceTrigger(event: .toBattery).trigger
        #expect(toBattery.matches(.powerSourceChanged(isOnExternalPower: false)))
        #expect(!toBattery.matches(.powerSourceChanged(isOnExternalPower: true)))
    }

    @Test func batteryAndNonEventTriggersDoNotMatchStatelessly() {
        let battery = BatteryThresholdTrigger(comparator: .below, percentage: 20).trigger
        #expect(!battery.matches(.batteryChanged(percentage: 15)))
        #expect(!TriggerConfiguration.manual(ManualTrigger()).matches(.woke))
        #expect(!TriggerConfiguration.schedule(.daily(hour: 9, minute: 0)).matches(.woke))
    }

    @Test func canonicalPhrasesDescribeTriggers() {
        #expect(CanonicalPhrase.text(for: .applicationLifecycle(ApplicationLifecycleTrigger(application: safari, event: .launched))) == "When Safari opens")
        #expect(CanonicalPhrase.text(for: .wake(WakeTrigger())) == "When the Mac wakes")
        #expect(CanonicalPhrase.text(for: .powerSource(PowerSourceTrigger(event: .toBattery))) == "When the Mac switches to battery")
        #expect(CanonicalPhrase.text(for: .batteryThreshold(BatteryThresholdTrigger(comparator: .below, percentage: 20))) == "When the battery drops below 20%")
    }

    @Test func parsesWhenApplicationOpens() {
        let parsed = CommandParser().parse("when Safari opens")
        #expect(parsed.outcome == .complete)
        let clause = parsed.clauses.first { $0.kind == .applicationLifecycle }
        #expect(clause?.lifecycleEvent == .launched)
        #expect(clause?.lifecycleApplicationName == "Safari")
    }

    @Test func parsesWhenApplicationQuits() {
        let parsed = CommandParser().parse("when Google Chrome quits")
        let clause = parsed.clauses.first { $0.kind == .applicationLifecycle }
        #expect(clause?.lifecycleEvent == .quit)
        #expect(clause?.lifecycleApplicationName == "Google Chrome")
    }

    @Test func whenWithoutVerbNeedsInput() {
        let parsed = CommandParser().parse("when Safari")
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.diagnostics.contains { $0.severity == .error })
    }

    @Test func lifecycleComposerBuildsDefinition() {
        var document = ComposerDocument(text: "when Safari opens, then show a notification")
        #expect(document.trigger == .applicationLifecycle(application: nil, label: "Safari", event: .launched))
        #expect(document.makeDefinition(name: "Watch") == nil)

        document.setTrigger(
            .applicationLifecycle(
                application: safari,
                label: "Safari",
                event: .launched
            )
        )
        let definition = document.makeDefinition(name: "Watch")
        #expect(definition?.trigger.isEventTrigger == true)
    }

    @Test func parsesWakePhrase() {
        let parsed = CommandParser().parse("when the Mac wakes")
        #expect(parsed.outcome == .complete)
        #expect(parsed.clauses.first?.kind == .wake)
    }

    @Test func wakeComposerBuildsDefinition() {
        let document = ComposerDocument(text: "when the Mac wakes, then show a notification")
        #expect(document.trigger == .wake)
        let definition = document.makeDefinition(name: "Wake")
        #expect(definition?.trigger == .wake(WakeTrigger()))
    }

    @Test func reconcilerEstablishesBaselineThenReportsChanges() {
        var reconciler = DeviceStateReconciler()
        reconciler.establishBaseline(["A", "B"])
        #expect(reconciler.reconcile(["A", "B"]).isEmpty)

        let added = reconciler.reconcile(["A", "B", "C"])
        #expect(added.added == ["C"])
        #expect(added.removed.isEmpty)

        let removed = reconciler.reconcile(["A"])
        #expect(removed.removed == ["B", "C"])
        #expect(removed.added.isEmpty)
    }

    @Test func parsesDisplayAndVolumePhrases() {
        let parser = CommandParser()

        let connected = parser.parse("when a display connects")
        #expect(connected.outcome == .complete)
        #expect(connected.clauses.first?.kind == .displayConnection)
        #expect(connected.clauses.first?.displayEvent == .connected)

        let disconnected = parser.parse("when an external display disconnects")
        #expect(disconnected.clauses.first?.displayEvent == .disconnected)

        let mounted = parser.parse("when an external drive mounts")
        #expect(mounted.outcome == .complete)
        #expect(mounted.clauses.first?.kind == .externalVolume)
        #expect(mounted.clauses.first?.volumeEvent == .mounted)

        let unmounted = parser.parse("when a drive unmounts")
        #expect(unmounted.clauses.first?.volumeEvent == .unmounted)
    }

    @Test func displayAndVolumeComposerBuildDefinitions() {
        let display = ComposerDocument(text: "when a display connects, then show a notification")
        #expect(display.makeDefinition(name: "Display")?.trigger == .displayConnection(DisplayConnectionTrigger(selection: .anyExternal, event: .connected)))

        let volume = ComposerDocument(text: "when an external drive mounts, then show a notification")
        #expect(volume.makeDefinition(name: "Drive")?.trigger == .externalVolume(ExternalVolumeTrigger(selection: .anyExternal, event: .mounted)))
    }

    @Test func eventTriggerRoundTripsThroughCoding() throws {
        let definition = AutomationDefinition(
            name: "Display",
            trigger: .displayConnection(DisplayConnectionTrigger(selection: .anyExternal, event: .connected)),
            actions: [.wait(WaitAction(duration: 1))]
        )
        let data = try AutomationCoding.encode(definition)
        let decoded = try AutomationCoding.decode(data)
        #expect(decoded.trigger == definition.trigger)
    }
}

private extension ApplicationLifecycleTrigger {
    var trigger: TriggerConfiguration { .applicationLifecycle(self) }
}

private extension WakeTrigger {
    var trigger: TriggerConfiguration { .wake(self) }
}

private extension BatteryThresholdTrigger {
    var trigger: TriggerConfiguration { .batteryThreshold(self) }
}

private extension DisplayConnectionTrigger {
    var trigger: TriggerConfiguration { .displayConnection(self) }
}

private extension ExternalVolumeTrigger {
    var trigger: TriggerConfiguration { .externalVolume(self) }
}

private extension PowerSourceTrigger {
    var trigger: TriggerConfiguration { .powerSource(self) }
}
