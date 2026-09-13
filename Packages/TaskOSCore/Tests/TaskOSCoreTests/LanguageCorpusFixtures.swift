import Foundation
@testable import TaskOSCore

struct CorpusClauseExpectation: Equatable {
    enum Parameter: Equatable {
        case none
        case duration(TimeInterval)
        case copyText(String)
        case preset(WindowPreset)
        case fileSelection(FileTarget.Kind)
    }

    let kind: ParsedClauseKind
    let names: [String]
    let parameter: Parameter
}

struct CorpusCommand: Equatable {
    let text: String
    let clauses: [CorpusClauseExpectation]
}

enum LanguageCorpus {
    static let seed: UInt64 = 0x2_7_D1_2026

    struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed
        }

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    static let plainAppNames = ["Safari", "Notes", "Calculator", "Mail"]
    static let quotedAppNames = ["Google Chrome", "Visual Studio Code", "Research and Notes"]
    static let waitChoices: [(text: String, seconds: TimeInterval)] = [
        ("1 second", 1),
        ("2 seconds", 2),
        ("5 seconds", 5),
        ("30 seconds", 30),
        ("0.5 seconds", 0.5),
    ]
    static let copyLiterals = ["hello", "meeting agenda", "a, b; c then d"]
    static let urls = ["https://example.com", "http://example.com/path?q=1#frag"]
    static let arrangePresets: [(text: String, preset: WindowPreset)] = [
        ("on the left half", .leftHalf),
        ("on the right half", .rightHalf),
        ("on the top half", .topHalf),
        ("on the bottom half", .bottomHalf),
        ("on the top-left quarter", .topLeftQuarter),
        ("on the top-right quarter", .topRightQuarter),
        ("on the bottom-left quarter", .bottomLeftQuarter),
        ("on the bottom-right quarter", .bottomRightQuarter),
    ]
    static let connectors = ["then", "and then", "and", "also", ",", ";", "after that", "next", "followed by"]

    static func randomAction(_ generator: inout SeededGenerator) -> CorpusCommand {
        switch Int.random(in: 0..<12, using: &generator) {
        case 0:
            let name = plainAppNames.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Open \(name)",
                clauses: [CorpusClauseExpectation(kind: .openApplication, names: [name], parameter: .none)]
            )
        case 1:
            let name = quotedAppNames.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Open \"\(name)\"",
                clauses: [CorpusClauseExpectation(kind: .openApplication, names: [name], parameter: .none)]
            )
        case 2:
            let name = plainAppNames.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Hide \(name)",
                clauses: [CorpusClauseExpectation(kind: .hideApplication, names: [name], parameter: .none)]
            )
        case 3:
            let name = plainAppNames.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Quit \(name)",
                clauses: [CorpusClauseExpectation(kind: .quitApplication, names: [name], parameter: .none)]
            )
        case 4:
            let wait = waitChoices.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Wait \(wait.text)",
                clauses: [CorpusClauseExpectation(kind: .wait, names: [], parameter: .duration(wait.seconds))]
            )
        case 5:
            return CorpusCommand(
                text: "Show a notification",
                clauses: [CorpusClauseExpectation(kind: .showNotification, names: [], parameter: .none)]
            )
        case 6:
            return CorpusCommand(
                text: "Notify",
                clauses: [CorpusClauseExpectation(kind: .showNotification, names: [], parameter: .none)]
            )
        case 7:
            let literal = copyLiterals.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Copy \"\(literal)\"",
                clauses: [CorpusClauseExpectation(kind: .copyText, names: [], parameter: .copyText(literal))]
            )
        case 8:
            return CorpusCommand(
                text: "Reveal the selected item",
                clauses: [CorpusClauseExpectation(kind: .revealInFinder, names: [], parameter: .fileSelection(.file))]
            )
        case 9:
            let command = Bool.random(using: &generator) ? "Open the selected file" : "Open the selected folder"
            let kind: FileTarget.Kind = command.hasSuffix("folder") ? .folder : .file
            return CorpusCommand(
                text: command,
                clauses: [CorpusClauseExpectation(kind: .openFile, names: [], parameter: .fileSelection(kind))]
            )
        case 10:
            let name = plainAppNames.randomElement(using: &generator)!
            let preset = arrangePresets.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Put \(name) \(preset.text)",
                clauses: [CorpusClauseExpectation(kind: .arrangeWindow, names: [], parameter: .preset(preset.preset))]
            )
        default:
            let url = urls.randomElement(using: &generator)!
            return CorpusCommand(
                text: "Open \(url)",
                clauses: [CorpusClauseExpectation(kind: .openApplication, names: [url], parameter: .none)]
            )
        }
    }

    static func positiveCommands(count: Int = 2_000) -> [CorpusCommand] {
        var generator = SeededGenerator(seed: seed)
        var commands: [CorpusCommand] = []
        while commands.count < count {
            let actionCount = Int.random(in: 1...3, using: &generator)
            var parts: [String] = []
            var expectations: [CorpusClauseExpectation] = []
            for index in 0..<actionCount {
                if index > 0 {
                    parts.append(connectors[Int.random(in: 0..<connectors.count, using: &generator)])
                }
                let action = randomAction(&generator)
                parts.append(action.text)
                expectations.append(contentsOf: action.clauses)
            }
            commands.append(CorpusCommand(text: parts.joined(separator: " "), clauses: expectations))
        }
        return commands
    }

    static func negativeCommands() -> [String] {
        var cases: [String] = [
            "",
            "frobnicate",
            "open",
            "hide",
            "quit",
            "wait",
            "wait seconds",
            "wait 0.05 seconds",
            "wait 31 seconds",
            "show",
            "copy",
            "copy agenda",
            "copy \"unclosed text",
            "reveal the selected",
            "put Safari",
            "arrange Safari",
            "when Safari closes",
            "when Safari opens and when Safari quits",
            "when the battery drops below",
            "every day at 9",
            "every day at 09:00",
            "once on 2027-02-29 at 09:00",
            "once on 2026-13-01 at 09:00",
            "once on 2026-09-20 at 25:00",
            "once on 2026-09-20",
            "once on 2026-09-20 at 9:00",
            "do not open Safari",
            "not open Safari",
            "open Safari and not Notes",
            "open Safari and then not Notes",
            "never quit Notes",
            "open Safari and email Bob",
            "open Safari, then email Bob",
            "open Safari and delete Downloads",
            "open Safari so I can delete Downloads",
            "copy \"text\" and delete Files",
            "every day at 9 am, then every 30 minutes, then open Safari",
            "every day at 9 am at 10 am",
            "open Safari, then every day at 9 am, then open Notes",
            "open Notes so I can write extra text",
            "open Notes so I can open Notes every day",
            "open Notes so I can write, then erase Downloads.",
            "wait 1 second except on weekends",
            "wait 1 second and run Scripts",
            "show a notification on weekends",
            "open Notes and remove Files",
            "in 5 seconds except on weekends",
        ]

        let prefixes = ["open Safari", "wait 1 second", "show a notification", "copy \"hello\"", "hide Notes"]
        let tails = [
            " and delete Downloads", " and email Bob", " and send Mail", " and message Bob",
            " and remove Files", " and move Everything", " and rename Docs", " and run Scripts",
            " and execute Code", " and script Stuff", " and shortcut X", " and click Here",
            " and type Text", " and upload File", " and download Item",
            " so I can do whatever I want", " and not open Notes",
        ]
        for prefix in prefixes {
            for tail in tails {
                cases.append(prefix + tail)
            }
        }
        return cases
    }

    static let ambiguityFixtures: [(command: String, question: String)] = [
        ("every day at 9", "Specify a time, for example every day at 9 am, or in 30 minutes."),
        ("every day at 09:00", "Specify a time, for example every day at 9 am, or in 30 minutes."),
        ("every 30 minutes, then every day at 9 am", "Use only one trigger."),
        (
            "open Safari, then every day at 9 am, then open Notes",
            "Put the trigger at the start or the end of the command."
        ),
    ]
}
