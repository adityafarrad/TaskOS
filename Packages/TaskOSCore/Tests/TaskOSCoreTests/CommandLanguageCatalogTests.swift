import Testing
import Foundation
@testable import TaskOSCore

@Suite("Command language catalog")
struct CommandLanguageCatalogTests {
    private let catalog = CommandLanguageCatalog.standard
    private let parser = CommandParser()

    @Test func everyExecutableCapabilityHasOneLanguageEntry() {
        #expect(Set(catalog.actions.keys) == Set(ActionID.allCases))
        #expect(Set(catalog.triggers.keys) == Set(TriggerID.allCases))

        for (id, entry) in catalog.actions {
            #expect(entry.id == id)
        }
        for (id, entry) in catalog.triggers {
            #expect(entry.id == id)
        }
    }

    @Test func everyAliasHeadWordHasAParserRoute() {
        for entry in catalog.actions.values {
            for word in entry.headWords {
                #expect(catalog.clauseRoutes[word] != nil, "\(word) has no parser route")
                #expect(word == word.lowercased())
                #expect(!word.contains(" "))
            }
        }
        for entry in catalog.triggers.values {
            for word in entry.headWords {
                #expect(catalog.clauseRoutes[word] != nil, "\(word) has no parser route")
            }
        }
    }

    @Test func catalogExamplesParseToTheirCapability() {
        for id in ActionID.allCases {
            guard let entry = catalog.actions[id] else { continue }
            #expect(!entry.examples.isEmpty, "\(id) has no examples")
            for example in entry.examples {
                let parsed = parser.parse(example)
                #expect(
                    parsed.clauses.contains { $0.kind == clauseKind(for: id) },
                    "\(id) example did not parse: \(example)"
                )
            }
        }

        for id in TriggerID.allCases {
            guard let entry = catalog.triggers[id] else { continue }
            if entry.usesImplicitGrammar {
                #expect(entry.examples.isEmpty)
                continue
            }
            #expect(!entry.examples.isEmpty, "\(id) has no examples")
            guard let kind = clauseKind(for: id) else { continue }
            for example in entry.examples {
                let parsed = parser.parse(example)
                #expect(
                    parsed.clauses.contains { $0.kind == kind },
                    "\(id) example did not parse: \(example)"
                )
            }
        }
    }

    @Test func websiteExampleIsClassifiedAsWebsite() {
        let parsed = parser.parse("Open https://example.com")
        #expect(parsed.clauses.contains { $0.kind == .openApplication })
        #expect(
            parsed.clauses.flatMap(\.resourceNames)
                .contains { ResourceNameHeuristics.isWebsite($0) }
        )
    }

    @Test func canonicalActionPhrasesReparse() {
        for id in ActionID.allCases {
            let phrase = CanonicalPhrase.text(for: sampleAction(id))
            let parsed = parser.parse(phrase)
            #expect(
                parsed.clauses.contains { $0.kind == clauseKind(for: id) },
                "\(id) canonical phrase did not reparse: \(phrase)"
            )
        }
    }

    @Test func canonicalTriggerPhrasesReparse() {
        for id in TriggerID.allCases {
            guard let kind = clauseKind(for: id) else {
                #expect(catalog.triggers[id]?.usesImplicitGrammar == true)
                #expect(CanonicalPhrase.text(for: sampleTrigger(id)) == "Manually")
                continue
            }
            let phrase = CanonicalPhrase.text(for: sampleTrigger(id))
            let parsed = parser.parse(phrase)
            #expect(
                parsed.clauses.contains { $0.kind == kind },
                "\(id) canonical phrase did not reparse: \(phrase)"
            )
        }
    }

    @Test func canonicalScheduleFormsReparse() {
        let samples: [ScheduleTrigger] = [
            .daily(hour: 9, minute: 0),
            .daily(hour: 21, minute: 30),
            .weekdays([.monday, .friday], hour: 17, minute: 15),
            .interval(every: 30 * 60, startingAt: Date(timeIntervalSince1970: 1_000_000)),
            .interval(every: 60 * 60, startingAt: Date(timeIntervalSince1970: 1_000_000)),
        ]
        for schedule in samples {
            let phrase = CanonicalPhrase.text(for: schedule)
            let parsed = parser.parse(phrase)
            #expect(
                parsed.clauses.contains { $0.kind == .schedule },
                "schedule canonical phrase did not reparse: \(phrase)"
            )
            #expect(parsed.outcome == .complete, "schedule canonical phrase was incomplete: \(phrase)")
        }
    }

    @Test func absoluteOneTimeFormRoundTrips() {
        #expect(catalog.scheduleTemplate("oneTime")?.format == "Once on {date}")

        guard let date = Calendar.current.date(
            from: DateComponents(year: 2026, month: 9, day: 20, hour: 9, minute: 0)
        ) else {
            Issue.record("Could not build the sample date")
            return
        }

        let phrase = CanonicalPhrase.text(for: ScheduleTrigger.oneTime(date))
        #expect(phrase == "Once on 2026-09-20 at 09:00")

        let parsed = parser.parse(phrase)
        #expect(parsed.outcome == .complete)
        #expect(
            parsed.clauses.compactMap(\.schedule).first
                == .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)
        )
    }

    @Test func suggestionsUseCatalogWording() {
        let engine = SuggestionEngine(limit: 20)
        let starters = engine.suggestions(for: "")

        for id in ActionID.allCases {
            guard let starter = catalog.actionStarter(id) else {
                Issue.record("Missing starter for \(id)")
                continue
            }
            guard let suggestion = starters.first(where: { $0.id == starter.id }) else {
                Issue.record("Starter \(starter.id) was not offered")
                continue
            }
            #expect(suggestion.phrase == starter.phrase)
            #expect(suggestion.title == starter.title)
            #expect(suggestion.category == starter.category)
            #expect(suggestion.requiresParameter == starter.requiresParameter)
        }

        let whenSuggestions = engine.suggestions(for: "when")
        for starter in catalog.whenStarters() {
            #expect(
                whenSuggestions.contains {
                    $0.id == starter.id && $0.phrase == starter.phrase && $0.title == starter.title
                },
                "Trigger starter \(starter.id) was not offered"
            )
        }

        let waits = engine.suggestions(for: "wait")
        #expect(Set(waits.map(\.phrase)) == Set(catalog.waitStarters.map(\.phrase)))

        #expect(
            engine.suggestions(for: "show").first?.phrase == catalog.notificationStarter.phrase
        )

        #expect(
            engine.suggestions(for: "open apple.com")
                .contains { $0.phrase == catalog.websitePhrase(url: "https://apple.com") }
        )
    }

    @Test func suggestionStartersAreParserRecognized() {
        var seeds = catalog.actions.values.compactMap(\.starter)
        seeds.append(contentsOf: catalog.whenStarters())
        seeds.append(contentsOf: catalog.waitStarters)
        seeds.append(catalog.notificationStarter)

        for seed in seeds {
            let parsed = parser.parse(seed.phrase)
            #expect(parsed.outcome != .unrecognized, "Starter is not recognized: \(seed.phrase)")
            #expect(
                !parsed.clauses.contains { $0.kind == .unsupported },
                "Starter is excluded: \(seed.phrase)"
            )
        }
    }

    @Test func clauseRoutesAreParserRecognized() {
        let samples: [CommandClauseRoute: (phrase: String, kind: ParsedClauseKind)] = [
            .open: ("open", .openApplication),
            .hideApplication: ("hide", .hideApplication),
            .quitApplication: ("quit", .quitApplication),
            .reveal: ("reveal", .revealInFinder),
            .wait: ("wait", .wait),
            .notification: ("show a notification", .showNotification),
            .copy: ("copy", .copyText),
            .arrange: ("put", .arrangeWindow),
            .maximize: ("maximize", .arrangeWindow),
            .center: ("center", .arrangeWindow),
            .schedule: ("every", .schedule),
            .when: ("when", .applicationLifecycle),
        ]

        #expect(Set(catalog.clauseRoutes.values) == Set(samples.keys))
        #expect(catalog.clauseRoutes["show"] == .notification)
        #expect(catalog.clauseRoutes["notify"] == .notification)

        for (_, sample) in samples {
            let parsed = parser.parse(sample.phrase)
            #expect(parsed.clauses.contains { $0.kind == sample.kind }, "\(sample.phrase) was not recognized")
            #expect(
                !parsed.clauses.contains { $0.kind == .unrecognized || $0.kind == .unsupported },
                "\(sample.phrase) fell through the parser"
            )
        }
    }

    @Test func presetPhrasesAreCatalogOwned() {
        for preset in WindowPreset.allCases {
            #expect(preset.phraseSuffix == catalog.arrangePresetPhrase(preset))
        }
    }

    @Test func catalogDoesNotContainApplicationIdentityAliases() {
        let strings = catalogStrings()
        let applicationAliases = ["VS Code", "Visual Studio Code", "Google Chrome", "com.apple"]
        for alias in applicationAliases {
            #expect(
                !strings.contains { $0.localizedCaseInsensitiveContains(alias) },
                "Application alias leaked into the catalog: \(alias)"
            )
        }
    }

    @Test func runtimeSourcesDoNotDependOnTheLanguageCatalog() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = packageRoot.appendingPathComponent("Sources/TaskOSCore")

        let runtimeFiles = [
            "CreationPreparer.swift",
            "WorkflowRunner.swift",
            "ActionExecutor.swift",
            "Permissions.swift",
            "RunCoordinator.swift",
            "ApprovalRegistry.swift",
            "ScheduleRegistry.swift",
            "EventTriggerRegistry.swift",
        ]

        var inspected = 0
        for name in runtimeFiles {
            let url = sourcesRoot.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            inspected += 1
            let contents = try String(contentsOf: url, encoding: .utf8)
            #expect(
                !contents.contains("CommandLanguageCatalog"),
                "\(name) must not depend on the language catalog"
            )
        }
        #expect(inspected == runtimeFiles.count)
    }

    private func clauseKind(for id: ActionID) -> ParsedClauseKind {
        switch id {
        case .openApplication: return .openApplication
        case .hideApplication: return .hideApplication
        case .quitApplication: return .quitApplication
        case .openFile: return .openFile
        case .revealInFinder: return .revealInFinder
        case .openWebsite: return .openApplication
        case .arrangeWindow: return .arrangeWindow
        case .wait: return .wait
        case .showNotification: return .showNotification
        case .copyText: return .copyText
        }
    }

    private func clauseKind(for id: TriggerID) -> ParsedClauseKind? {
        switch id {
        case .manual: return nil
        case .schedule: return .schedule
        case .applicationLifecycle: return .applicationLifecycle
        case .wake: return .wake
        case .displayConnection: return .displayConnection
        case .externalVolume: return .externalVolume
        case .powerSource: return .powerSource
        case .batteryThreshold: return .batteryThreshold
        }
    }

    private func sampleAction(_ id: ActionID) -> ActionConfiguration {
        let app = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        switch id {
        case .openApplication:
            return .openApplication(OpenApplicationAction(application: app))
        case .hideApplication:
            return .hideApplication(HideApplicationAction(application: app))
        case .quitApplication:
            return .quitApplication(QuitApplicationAction(application: app))
        case .openFile:
            return .openFile(
                OpenFileAction(target: FileTarget(kind: .file, displayName: "f", path: "/tmp/f"))
            )
        case .revealInFinder:
            return .revealInFinder(
                RevealInFinderAction(target: FileTarget(kind: .file, displayName: "f", path: "/tmp/f"))
            )
        case .openWebsite:
            return .openWebsite(OpenWebsiteAction(url: "https://example.com"))
        case .arrangeWindow:
            return .arrangeWindow(ArrangeWindowAction(application: app, preset: .leftHalf))
        case .wait:
            return .wait(WaitAction(duration: 5))
        case .showNotification:
            return .showNotification(ShowNotificationAction(title: "T", message: "M"))
        case .copyText:
            return .copyText(CopyTextAction(text: "meeting agenda"))
        }
    }

    private func sampleTrigger(_ id: TriggerID) -> TriggerConfiguration {
        let app = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        switch id {
        case .manual:
            return .manual(ManualTrigger())
        case .schedule:
            return .schedule(.daily(hour: 9, minute: 0))
        case .applicationLifecycle:
            return .applicationLifecycle(
                ApplicationLifecycleTrigger(application: app, event: .launched)
            )
        case .wake:
            return .wake(WakeTrigger())
        case .displayConnection:
            return .displayConnection(
                DisplayConnectionTrigger(selection: .anyExternal, event: .connected)
            )
        case .externalVolume:
            return .externalVolume(
                ExternalVolumeTrigger(selection: .anyExternal, event: .mounted)
            )
        case .powerSource:
            return .powerSource(PowerSourceTrigger(event: .toBattery))
        case .batteryThreshold:
            return .batteryThreshold(
                BatteryThresholdTrigger(comparator: .below, percentage: 20)
            )
        }
    }

    private func catalogStrings() -> [String] {
        var strings: [String] = []
        strings.append(contentsOf: catalog.clauseRoutes.keys)
        strings.append(contentsOf: catalog.excluded.keys)
        strings.append(contentsOf: catalog.excluded.values)
        strings.append(contentsOf: catalog.shared.connectorWords)
        strings.append(contentsOf: catalog.shared.connectorPunctuation)
        strings.append(catalog.shared.actionJoiner)
        strings.append(contentsOf: catalog.file.selectionPhrases.keys)
        strings.append(contentsOf: catalog.file.revealPhrases)
        strings.append(contentsOf: catalog.notification.directWords)
        strings.append(contentsOf: catalog.notification.articles)
        strings.append(contentsOf: catalog.notification.nouns)
        strings.append(contentsOf: catalog.wait.optionalWords)
        strings.append(contentsOf: catalog.wait.timeUnits)
        strings.append(contentsOf: catalog.copy.optionalWords)
        strings.append(contentsOf: catalog.arrange.joiners)
        strings.append(contentsOf: catalog.arrange.articles)
        strings.append(contentsOf: catalog.arrange.sides)
        strings.append(contentsOf: catalog.arrange.horizontalSides)
        strings.append(contentsOf: catalog.arrange.halfNouns)
        strings.append(contentsOf: [
            catalog.arrange.leftWord,
            catalog.arrange.rightWord,
            catalog.arrange.topWord,
            catalog.arrange.bottomWord,
        ])
        strings.append(contentsOf: catalog.arrange.presetPhrases.values)
        strings.append(contentsOf: catalog.schedule.headWords)
        strings.append(contentsOf: [
            catalog.schedule.everyWord,
            catalog.schedule.onceWord,
            catalog.schedule.inWord,
            catalog.schedule.atWord,
        ])
        strings.append(contentsOf: catalog.schedule.dayWords)
        strings.append(contentsOf: catalog.schedule.weekdayWords)
        strings.append(contentsOf: catalog.schedule.weekendWords)
        strings.append(contentsOf: catalog.schedule.weekdayNames.keys)
        strings.append(contentsOf: catalog.schedule.durationUnits.keys)
        strings.append(contentsOf: catalog.schedule.timeUnits)
        strings.append(contentsOf: catalog.schedule.meridiemAM)
        strings.append(contentsOf: catalog.schedule.meridiemPM)
        strings.append(contentsOf: catalog.trigger.headWords)
        strings.append(contentsOf: catalog.trigger.wakePhrases)
        strings.append(contentsOf: catalog.trigger.lifecycleVerbs.keys)
        strings.append(contentsOf: catalog.trigger.displaySubjects)
        strings.append(contentsOf: catalog.trigger.displayConnectWords)
        strings.append(contentsOf: catalog.trigger.displayDisconnectWords)
        strings.append(contentsOf: catalog.trigger.volumeSubjects)
        strings.append(contentsOf: catalog.trigger.volumeMountWords)
        strings.append(contentsOf: catalog.trigger.volumeUnmountWords)
        strings.append(contentsOf: catalog.trigger.powerSubjects)
        strings.append(contentsOf: catalog.trigger.powerToBatterySuffixes)
        strings.append(contentsOf: catalog.trigger.powerToExternalSuffixes)
        strings.append(contentsOf: catalog.trigger.batterySubjects)
        strings.append(contentsOf: catalog.trigger.batteryBelowWords)
        strings.append(contentsOf: catalog.trigger.batteryAboveWords)
        strings.append(contentsOf: catalog.trigger.batteryDirectionWords.values)

        for entry in catalog.actions.values {
            strings.append(contentsOf: entry.headWords)
            strings.append(contentsOf: entry.examples)
            strings.append(entry.guideExample)
            strings.append(entry.canonical.standard.format)
            strings.append(contentsOf: entry.canonical.variants.values.map(\.format))
            if let starter = entry.starter {
                strings.append(contentsOf: [starter.id, starter.phrase, starter.title])
            }
        }

        for entry in catalog.triggers.values {
            strings.append(contentsOf: entry.headWords)
            strings.append(contentsOf: entry.examples)
            strings.append(entry.guideExample)
            strings.append(entry.canonical.standard.format)
            strings.append(contentsOf: entry.canonical.variants.values.map(\.format))
            if let starter = entry.starter {
                strings.append(contentsOf: [starter.id, starter.phrase, starter.title])
            }
        }

        for starter in catalog.waitStarters {
            strings.append(contentsOf: [starter.id, starter.phrase, starter.title])
        }
        strings.append(contentsOf: [
            catalog.notificationStarter.id,
            catalog.notificationStarter.phrase,
            catalog.notificationStarter.title,
        ])

        return strings
    }
}
