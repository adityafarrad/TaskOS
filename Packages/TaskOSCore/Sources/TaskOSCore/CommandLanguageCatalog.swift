import Foundation

public struct CanonicalTemplate: Hashable, Sendable {
    public let format: String

    public init(_ format: String) {
        self.format = format
    }

    public func render(_ values: [String: String] = [:]) -> String {
        var result = format
        for (slot, value) in values {
            result = result.replacingOccurrences(of: "{\(slot)}", with: value)
        }
        return result
    }
}

public enum CommandClauseRoute: Hashable, Sendable {
    case open
    case hideApplication
    case quitApplication
    case reveal
    case wait
    case notification
    case copy
    case arrange
    case maximize
    case center
    case schedule
    case when
}

public struct CommandLanguageCatalog: Sendable {
    public struct CanonicalWording: Hashable, Sendable {
        public let standard: CanonicalTemplate
        public let variants: [String: CanonicalTemplate]

        public init(_ standard: String, variants: [String: String] = [:]) {
            self.standard = CanonicalTemplate(standard)
            self.variants = variants.mapValues(CanonicalTemplate.init)
        }

        public func template(_ variant: String? = nil) -> CanonicalTemplate {
            if let variant, let found = variants[variant] {
                return found
            }
            return standard
        }
    }

    public struct CompletionStarter: Hashable, Sendable {
        public let id: String
        public let phrase: String
        public let title: String
        public let category: Suggestion.Category
        public let requiresParameter: Bool

        public init(
            id: String,
            phrase: String,
            title: String,
            category: Suggestion.Category,
            requiresParameter: Bool
        ) {
            self.id = id
            self.phrase = phrase
            self.title = title
            self.category = category
            self.requiresParameter = requiresParameter
        }
    }

    public struct ActionLanguage: Hashable, Sendable {
        public let id: ActionID
        public let headWords: [String]
        public let canonical: CanonicalWording
        public let examples: [String]
        public let guideExample: String
        public let starter: CompletionStarter?
    }

    public struct TriggerLanguage: Hashable, Sendable {
        public let id: TriggerID
        public let headWords: [String]
        public let canonical: CanonicalWording
        public let examples: [String]
        public let guideExample: String
        public let starter: CompletionStarter?
        public let usesImplicitGrammar: Bool
    }

    public struct SharedVocabulary: Hashable, Sendable {
        public let connectorWords: Set<String>
        public let connectorPunctuation: Set<String>
        public let actionJoiner: String
    }

    public struct FileVocabulary: Hashable, Sendable {
        public let selectionPhrases: [String: FileTarget.Kind]
        public let revealPhrases: Set<String>
    }

    public struct NotificationVocabulary: Hashable, Sendable {
        public let directWords: Set<String>
        public let articles: Set<String>
        public let nouns: Set<String>
    }

    public struct WaitVocabulary: Hashable, Sendable {
        public let optionalWords: Set<String>
        public let timeUnits: Set<String>
    }

    public struct CopyVocabulary: Hashable, Sendable {
        public let optionalWords: Set<String>
    }

    public struct ArrangeVocabulary: Hashable, Sendable {
        public let joiners: Set<String>
        public let articles: Set<String>
        public let sides: Set<String>
        public let horizontalSides: Set<String>
        public let halfNouns: Set<String>
        public let leftWord: String
        public let rightWord: String
        public let topWord: String
        public let bottomWord: String
        public let presetPhrases: [WindowPreset: String]
    }

    public struct ScheduleVocabulary: Hashable, Sendable {
        public let headWords: Set<String>
        public let everyWord: String
        public let onceWord: String
        public let inWord: String
        public let atWord: String
        public let dayWords: Set<String>
        public let weekdayWords: Set<String>
        public let weekendWords: Set<String>
        public let weekdayNames: [String: Weekday]
        public let durationUnits: [String: TimeInterval]
        public let timeUnits: Set<String>
        public let meridiemAM: Set<String>
        public let meridiemPM: Set<String>
    }

    public struct TriggerVocabulary: Hashable, Sendable {
        public let headWords: Set<String>
        public let wakePhrases: Set<String>
        public let lifecycleVerbs: [String: LifecycleEvent]
        public let displaySubjects: [String]
        public let displayConnectWords: Set<String>
        public let displayDisconnectWords: Set<String>
        public let volumeSubjects: [String]
        public let volumeMountWords: Set<String>
        public let volumeUnmountWords: Set<String>
        public let powerSubjects: [String]
        public let powerToBatterySuffixes: [String]
        public let powerToExternalSuffixes: [String]
        public let batterySubjects: [String]
        public let batteryBelowWords: [String]
        public let batteryAboveWords: [String]
        public let batteryDirectionWords: [ThresholdComparison: String]
    }

    public let actions: [ActionID: ActionLanguage]
    public let triggers: [TriggerID: TriggerLanguage]
    public let clauseRoutes: [String: CommandClauseRoute]
    public let shared: SharedVocabulary
    public let file: FileVocabulary
    public let notification: NotificationVocabulary
    public let wait: WaitVocabulary
    public let copy: CopyVocabulary
    public let arrange: ArrangeVocabulary
    public let schedule: ScheduleVocabulary
    public let trigger: TriggerVocabulary
    public let excluded: [String: String]
    public let waitStarters: [CompletionStarter]
    public let notificationStarter: CompletionStarter

    public var parameterStarters: [CompletionStarter] {
        waitStarters + [notificationStarter]
    }

    public func actionLanguage(_ id: ActionID) -> ActionLanguage? {
        actions[id]
    }

    public func triggerLanguage(_ id: TriggerID) -> TriggerLanguage? {
        triggers[id]
    }

    public func actionStarter(_ id: ActionID) -> CompletionStarter? {
        actions[id]?.starter
    }

    public func whenStarters() -> [CompletionStarter] {
        TriggerID.allCases.compactMap { triggers[$0]?.starter }
    }

    public func clauseStartWords() -> Set<String> {
        Set(clauseRoutes.keys).union(excluded.keys)
    }

    public func canonicalActionTemplate(_ id: ActionID, variant: String? = nil) -> CanonicalTemplate? {
        actions[id]?.canonical.template(variant)
    }

    public func guideExample(for id: ActionID) -> String? {
        actions[id]?.guideExample
    }

    public func guideExample(for id: TriggerID) -> String? {
        triggers[id]?.guideExample
    }

    public func canonicalTriggerTemplate(_ id: TriggerID, variant: String? = nil) -> CanonicalTemplate? {
        triggers[id]?.canonical.template(variant)
    }

    public func scheduleTemplate(_ variant: String) -> CanonicalTemplate? {
        triggers[.schedule]?.canonical.variants[variant]
    }

    public func arrangePresetPhrase(_ preset: WindowPreset) -> String {
        arrange.presetPhrases[preset] ?? preset.displayName
    }

    public func websitePhrase(url: String) -> String {
        canonicalActionTemplate(.openWebsite)?.render(["url": url]) ?? "Open \(url)"
    }

    public func clockText(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        var display = hour % 12
        if display == 0 { display = 12 }
        return String(format: "%d:%02d %@", display, minute, period)
    }

    public func intervalText(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60
        if minutes >= 60, minutes.truncatingRemainder(dividingBy: 60) == 0 {
            let hours = Int(minutes / 60)
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        let whole = Int(minutes)
        return whole == 1 ? "1 minute" : "\(whole) minutes"
    }
}

extension CommandLanguageCatalog {
    public static let standard = CommandLanguageCatalog(
        actions: standardActions,
        triggers: standardTriggers,
        clauseRoutes: [
            "open": .open,
            "hide": .hideApplication,
            "quit": .quitApplication,
            "reveal": .reveal,
            "wait": .wait,
            "show": .notification,
            "notify": .notification,
            "copy": .copy,
            "put": .arrange,
            "arrange": .arrange,
            "maximize": .maximize,
            "center": .center,
            "every": .schedule,
            "once": .schedule,
            "in": .schedule,
            "when": .when,
        ],
        shared: SharedVocabulary(
            connectorWords: ["and", "then", "also"],
            connectorPunctuation: [","],
            actionJoiner: ", then "
        ),
        file: FileVocabulary(
            selectionPhrases: [
                "the selected file": .file,
                "the selected folder": .folder,
            ],
            revealPhrases: ["the selected item", "the selected file", "the selected folder"]
        ),
        notification: NotificationVocabulary(
            directWords: ["notify"],
            articles: ["a", "the"],
            nouns: ["notification"]
        ),
        wait: WaitVocabulary(
            optionalWords: ["for"],
            timeUnits: ["second", "seconds", "sec", "secs", "s"]
        ),
        copy: CopyVocabulary(
            optionalWords: ["text"]
        ),
        arrange: ArrangeVocabulary(
            joiners: ["on", "to"],
            articles: ["the"],
            sides: ["left", "right", "top", "bottom"],
            horizontalSides: ["left", "right"],
            halfNouns: ["half"],
            leftWord: "left",
            rightWord: "right",
            topWord: "top",
            bottomWord: "bottom",
            presetPhrases: [
                .leftHalf: "on the left half",
                .rightHalf: "on the right half",
                .topHalf: "on the top half",
                .bottomHalf: "on the bottom half",
                .topLeftQuarter: "on the top-left quarter",
                .topRightQuarter: "on the top-right quarter",
                .bottomLeftQuarter: "on the bottom-left quarter",
                .bottomRightQuarter: "on the bottom-right quarter",
                .maximize: "maximized",
                .center: "centered",
            ]
        ),
        schedule: ScheduleVocabulary(
            headWords: ["every", "once", "in"],
            everyWord: "every",
            onceWord: "once",
            inWord: "in",
            atWord: "at",
            dayWords: ["day", "days"],
            weekdayWords: ["weekday", "weekdays"],
            weekendWords: ["weekend", "weekends"],
            weekdayNames: [
                "sunday": .sunday,
                "monday": .monday,
                "tuesday": .tuesday,
                "wednesday": .wednesday,
                "thursday": .thursday,
                "friday": .friday,
                "saturday": .saturday,
            ],
            durationUnits: [
                "minute": 60, "minutes": 60, "min": 60, "mins": 60,
                "hour": 3600, "hours": 3600, "hr": 3600, "hrs": 3600,
            ],
            timeUnits: ["second", "seconds", "sec", "secs", "s"],
            meridiemAM: ["am", "a.m", "a.m."],
            meridiemPM: ["pm", "p.m", "p.m."]
        ),
        trigger: TriggerVocabulary(
            headWords: ["when"],
            wakePhrases: ["the mac wakes", "the mac woke", "my mac wakes"],
            lifecycleVerbs: [
                "opens": .launched,
                "launches": .launched,
                "launched": .launched,
                "quits": .quit,
                "exits": .quit,
                "closes": .quit,
            ],
            displaySubjects: [
                "a display", "the display", "an external display", "the external display",
                "external display", "a monitor", "an external monitor", "the external monitor",
                "external monitor", "a screen", "an external screen", "the external screen",
            ],
            displayConnectWords: ["connects"],
            displayDisconnectWords: ["disconnects"],
            volumeSubjects: [
                "a drive", "the drive", "an external drive", "the external drive", "external drive",
                "a volume", "the volume", "an external volume", "the external volume", "external volume",
                "a disk", "the disk", "an external disk", "the external disk",
            ],
            volumeMountWords: ["mounts"],
            volumeUnmountWords: ["unmounts"],
            powerSubjects: ["the mac", "my mac", "this mac", "i"],
            powerToBatterySuffixes: [
                "switches to battery",
                "switch to battery",
                "switches to battery power",
                "switch to battery power",
                "is on battery",
            ],
            powerToExternalSuffixes: [
                "switches to power",
                "switch to power",
                "switches to external power",
                "switch to external power",
                "connects to power",
                "connect to power",
                "connects to external power",
                "connect to external power",
            ],
            batterySubjects: ["the battery", "my battery", "battery"],
            batteryBelowWords: ["drops below", "falls below", "goes below", "drops to", "falls to"],
            batteryAboveWords: ["rises above", "goes above", "rises to", "reaches"],
            batteryDirectionWords: [.below: "drops below", .above: "rises above"]
        ),
        excluded: [
            "email": "Sending email is not supported in this release.",
            "send": "Sending messages is not supported in this release.",
            "message": "Messaging is not supported in this release.",
            "delete": "Deleting or moving files is not supported in this release.",
            "remove": "Deleting or moving files is not supported in this release.",
            "move": "Deleting or moving files is not supported in this release.",
            "rename": "Renaming files is not supported in this release.",
            "run": "Running scripts or shell commands is not supported in this release.",
            "execute": "Running scripts or shell commands is not supported in this release.",
            "script": "Running scripts is not supported in this release.",
            "applescript": "AppleScript is not supported in this release.",
            "shortcut": "Running Apple Shortcuts is not supported in this release.",
            "click": "Simulating clicks is not supported in this release.",
            "type": "Sending keystrokes is not supported in this release.",
            "upload": "Uploading is not supported in this release.",
            "download": "Downloading is not supported in this release.",
        ],
        waitStarters: [
            CompletionStarter(
                id: "param.wait.1",
                phrase: "Wait 1 second",
                title: "Wait 1 second",
                category: .parameter,
                requiresParameter: false
            ),
            CompletionStarter(
                id: "param.wait.5",
                phrase: "Wait 5 seconds",
                title: "Wait 5 seconds",
                category: .parameter,
                requiresParameter: false
            ),
            CompletionStarter(
                id: "param.wait.30",
                phrase: "Wait 30 seconds",
                title: "Wait 30 seconds",
                category: .parameter,
                requiresParameter: false
            ),
        ],
        notificationStarter: CompletionStarter(
            id: "param.notification",
            phrase: "Show a notification",
            title: "Show a notification",
            category: .parameter,
            requiresParameter: false
        )
    )

    private static let standardActions: [ActionID: ActionLanguage] = [
        .openApplication: ActionLanguage(
            id: .openApplication,
            headWords: ["open"],
            canonical: CanonicalWording("Open {application}"),
            examples: ["Open Notes"],
            guideExample: "Open Safari",
            starter: CompletionStarter(
                id: "action.openApplication",
                phrase: "Open an application",
                title: "Open an application",
                category: .action,
                requiresParameter: true
            )
        ),
        .hideApplication: ActionLanguage(
            id: .hideApplication,
            headWords: ["hide"],
            canonical: CanonicalWording("Hide {application}"),
            examples: ["Hide Safari"],
            guideExample: "Hide Mail",
            starter: CompletionStarter(
                id: "action.hideApplication",
                phrase: "Hide Safari",
                title: "Hide an application",
                category: .action,
                requiresParameter: true
            )
        ),
        .quitApplication: ActionLanguage(
            id: .quitApplication,
            headWords: ["quit"],
            canonical: CanonicalWording("Quit {application}"),
            examples: ["Quit Safari"],
            guideExample: "Quit Safari",
            starter: CompletionStarter(
                id: "action.quitApplication",
                phrase: "Quit Safari",
                title: "Quit an application",
                category: .action,
                requiresParameter: true
            )
        ),
        .openFile: ActionLanguage(
            id: .openFile,
            headWords: ["open"],
            canonical: CanonicalWording(
                "Open the selected file",
                variants: ["folder": "Open the selected folder"]
            ),
            examples: ["Open the selected file", "Open the selected folder"],
            guideExample: "Open the selected file",
            starter: CompletionStarter(
                id: "action.openFile",
                phrase: "Open the selected file",
                title: "Open a file or folder",
                category: .action,
                requiresParameter: true
            )
        ),
        .revealInFinder: ActionLanguage(
            id: .revealInFinder,
            headWords: ["reveal"],
            canonical: CanonicalWording("Reveal the selected item"),
            examples: ["Reveal the selected item"],
            guideExample: "Reveal the selected item",
            starter: CompletionStarter(
                id: "action.revealInFinder",
                phrase: "Reveal the selected item",
                title: "Reveal in Finder",
                category: .action,
                requiresParameter: true
            )
        ),
        .openWebsite: ActionLanguage(
            id: .openWebsite,
            headWords: ["open"],
            canonical: CanonicalWording("Open {url}"),
            examples: ["Open https://example.com"],
            guideExample: "Open apple.com",
            starter: CompletionStarter(
                id: "action.openWebsite",
                phrase: "Open https://",
                title: "Open a website",
                category: .action,
                requiresParameter: true
            )
        ),
        .arrangeWindow: ActionLanguage(
            id: .arrangeWindow,
            headWords: ["put", "arrange", "maximize", "center"],
            canonical: CanonicalWording(
                "Put {application} {preset}",
                variants: [
                    "maximize": "Maximize {application}",
                    "center": "Center {application}",
                ]
            ),
            examples: ["Put Safari on the left half", "Maximize Safari", "Center Safari"],
            guideExample: "Put Safari on the left half",
            starter: CompletionStarter(
                id: "action.arrangeWindow",
                phrase: "Put an application on the left half",
                title: "Arrange a window",
                category: .action,
                requiresParameter: true
            )
        ),
        .wait: ActionLanguage(
            id: .wait,
            headWords: ["wait"],
            canonical: CanonicalWording("Wait {duration} seconds"),
            examples: ["Wait 5 seconds"],
            guideExample: "Wait 5 seconds",
            starter: CompletionStarter(
                id: "action.wait",
                phrase: "Wait 5 seconds",
                title: "Wait",
                category: .action,
                requiresParameter: true
            )
        ),
        .showNotification: ActionLanguage(
            id: .showNotification,
            headWords: ["show", "notify"],
            canonical: CanonicalWording("Show a notification"),
            examples: ["Show a notification", "Notify"],
            guideExample: "Show a notification",
            starter: CompletionStarter(
                id: "action.showNotification",
                phrase: "Show a notification",
                title: "Show a notification",
                category: .action,
                requiresParameter: false
            )
        ),
        .copyText: ActionLanguage(
            id: .copyText,
            headWords: ["copy"],
            canonical: CanonicalWording("Copy \"{text}\""),
            examples: ["Copy \"meeting agenda\""],
            guideExample: "Copy \"meeting agenda\"",
            starter: CompletionStarter(
                id: "action.copyText",
                phrase: "Copy \"text\"",
                title: "Copy text",
                category: .action,
                requiresParameter: true
            )
        ),
    ]

    private static let standardTriggers: [TriggerID: TriggerLanguage] = [
        .manual: TriggerLanguage(
            id: .manual,
            headWords: [],
            canonical: CanonicalWording("Manually"),
            examples: [],
            guideExample: "Manually open Safari and Notes",
            starter: nil,
            usesImplicitGrammar: true
        ),
        .schedule: TriggerLanguage(
            id: .schedule,
            headWords: ["every", "once", "in"],
            canonical: CanonicalWording(
                "Every day at {clock}",
                variants: [
                    "oneTime": "Once on {date}",
                    "daily": "Every day at {clock}",
                    "weekdays": "Every {days} at {clock}",
                    "interval": "Every {interval}",
                    "relative": "In {interval}",
                    "once": "Once at {clock}",
                ]
            ),
            examples: [
                "Every day at 09:00",
                "Every weekday at 09:00",
                "Every 30 minutes",
                "In 45 minutes",
                "Once at 19:00",
            ],
            guideExample: "Every weekday at 9 am open Safari",
            starter: nil,
            usesImplicitGrammar: false
        ),
        .applicationLifecycle: TriggerLanguage(
            id: .applicationLifecycle,
            headWords: ["when"],
            canonical: CanonicalWording("When {application} {event}"),
            examples: ["When Safari opens", "When Safari quits"],
            guideExample: "When Safari opens, show a notification",
            starter: CompletionStarter(
                id: "trigger.appLifecycle",
                phrase: "When Safari opens",
                title: "When an app opens or quits",
                category: .trigger,
                requiresParameter: true
            ),
            usesImplicitGrammar: false
        ),
        .wake: TriggerLanguage(
            id: .wake,
            headWords: ["when"],
            canonical: CanonicalWording("When the Mac wakes"),
            examples: ["When the Mac wakes"],
            guideExample: "When the Mac wakes, show a notification",
            starter: CompletionStarter(
                id: "trigger.wake",
                phrase: "When the Mac wakes",
                title: "When the Mac wakes",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .displayConnection: TriggerLanguage(
            id: .displayConnection,
            headWords: ["when"],
            canonical: CanonicalWording(
                "When {display} connects",
                variants: ["disconnected": "When {display} disconnects"]
            ),
            examples: ["When a display connects", "When an external display disconnects"],
            guideExample: "When a display connects, arrange Safari on the left half",
            starter: CompletionStarter(
                id: "trigger.display",
                phrase: "When a display connects",
                title: "When a display connects or disconnects",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .externalVolume: TriggerLanguage(
            id: .externalVolume,
            headWords: ["when"],
            canonical: CanonicalWording(
                "When {volume} mounts",
                variants: ["unmounted": "When {volume} unmounts"]
            ),
            examples: ["When an external drive mounts", "When a drive unmounts"],
            guideExample: "When an external drive mounts, open a folder",
            starter: CompletionStarter(
                id: "trigger.volume",
                phrase: "When an external drive mounts",
                title: "When an external drive mounts or unmounts",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .powerSource: TriggerLanguage(
            id: .powerSource,
            headWords: ["when"],
            canonical: CanonicalWording("When the Mac {event}"),
            examples: ["When the Mac switches to battery", "When I connect to power"],
            guideExample: "When the Mac switches to battery, show a notification",
            starter: CompletionStarter(
                id: "trigger.power",
                phrase: "When the Mac switches to battery",
                title: "When the power source changes",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .batteryThreshold: TriggerLanguage(
            id: .batteryThreshold,
            headWords: ["when"],
            canonical: CanonicalWording("When the battery {direction} {percentage}%"),
            examples: ["When the battery drops below 20%", "When the battery rises above 80%"],
            guideExample: "When the battery drops below 20%, show a notification",
            starter: CompletionStarter(
                id: "trigger.battery",
                phrase: "When the battery drops below 20%",
                title: "When the battery crosses a percentage",
                category: .trigger,
                requiresParameter: true
            ),
            usesImplicitGrammar: false
        ),
    ]
}
