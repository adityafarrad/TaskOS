import Testing
import Foundation
import TaskOSCore

@Suite("File actions")
struct FileActionTests {
    private let parser = CommandParser()
    private let pdf = FileTarget(kind: .file, displayName: "report.pdf", path: "/Users/me/report.pdf")

    @Test func parsesOpenSelectedFile() {
        let parsed = parser.parse("open the selected file")
        #expect(parsed.outcome == .complete)
        let clause = parsed.clauses.first { $0.kind == .openFile }
        #expect(clause?.fileSelectionKind == .file)
    }

    @Test func parsesOpenSelectedFolder() {
        let parsed = parser.parse("open the selected folder")
        let clause = parsed.clauses.first { $0.kind == .openFile }
        #expect(clause?.fileSelectionKind == .folder)
    }

    @Test func parsesRevealSelectedItem() {
        let parsed = parser.parse("reveal the selected item")
        #expect(parsed.outcome == .complete)
        let clause = parsed.clauses.first { $0.kind == .revealInFinder }
        #expect(clause?.fileSelectionKind == .file)
    }

    @Test func canonicalPhrasesRoundTrip() {
        let openFile = ActionConfiguration.openFile(OpenFileAction(target: pdf))
        let reveal = ActionConfiguration.revealInFinder(RevealInFinderAction(target: pdf))

        #expect(CanonicalPhrase.text(for: openFile) == "Open the selected file")
        #expect(CanonicalPhrase.text(for: reveal) == "Reveal the selected item")

        #expect(parser.parse(CanonicalPhrase.text(for: openFile)).clauses.first?.kind == .openFile)
        #expect(parser.parse(CanonicalPhrase.text(for: reveal)).clauses.first?.kind == .revealInFinder)
    }

    @Test func composerRequiresAFileSelection() {
        var document = ComposerDocument(text: "open the selected file")
        #expect(document.hasUnresolvedFiles)
        #expect(document.makeDefinition(name: "Files") == nil)

        guard let id = document.actions.first?.id else {
            Issue.record("Expected an action")
            return
        }
        document.updateAction(id: id, draft: .openFile(target: pdf))
        #expect(!document.hasUnresolvedFiles)
        #expect(document.makeDefinition(name: "Files") != nil)
    }

    @Test func selectionSurvivesTextEdits() {
        var document = ComposerDocument(text: "open the selected file")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected an action")
            return
        }
        document.updateAction(id: id, draft: .openFile(target: pdf))

        document.setText("open the selected file, then wait 1 second")
        #expect(document.actions.count == 2)
        if case .openFile(let target)? = document.actions.first?.draft {
            #expect(target == pdf)
        } else {
            Issue.record("Expected the selected file to be preserved")
        }
    }

    @Test func openFileRejectsExecutables() {
        let app = FileTarget(kind: .file, displayName: "Bad.app", path: "/Applications/Bad.app")
        #expect(!OpenFileAction(target: app).validate().isValid)
        #expect(pdf.isExecutableOrUnsupported == false)
        #expect(OpenFileAction(target: pdf).validate().isValid)
    }

    @Test func missingTargetIsInvalid() {
        #expect(!OpenFileAction(target: FileTarget(kind: .file, displayName: "", path: "")).validate().isValid)
        #expect(!RevealInFinderAction(target: FileTarget(kind: .file, displayName: "", path: "")).validate().isValid)
    }

    @Test func fileActionsRequireNoPermissions() {
        #expect(ActionConfiguration.openFile(OpenFileAction(target: pdf)).requiredPermissions.isEmpty)
        #expect(ActionConfiguration.revealInFinder(RevealInFinderAction(target: pdf)).requiredPermissions.isEmpty)
    }
}
