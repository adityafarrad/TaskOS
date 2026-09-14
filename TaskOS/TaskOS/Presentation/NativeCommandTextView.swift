import SwiftUI
import AppKit
import TaskOSCore

struct NativeCommandTextView: NSViewRepresentable {
    let text: String
    let selection: SourceSpan?
    let isFocused: Bool
    let onTextChange: (String, CommandEdit?) -> Void
    let onSelectionChange: (SourceSpan) -> Void
    let onMarkedTextChange: (Bool) -> Void
    let onFocusChange: (Bool) -> Void
    let onMoveHighlight: (Int) -> Bool
    let onAcceptHighlighted: () -> Bool
    let onAcceptSelected: () -> Bool
    let onEscape: () -> Bool
    let hasSuggestions: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 6)
        textView.textContainer?.lineFragmentPadding = 0
        textView.string = text
        textView.setAccessibilityLabel("Automation command")
        textView.setAccessibilityIdentifier("composer.field")

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        context.coordinator.textView = textView
        context.coordinator.lastReportedText = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let coordinator = context.coordinator
        if textView.string != text,
           !textView.hasMarkedText(),
           text != coordinator.lastReportedText {
            let previous = textView.selectedRange()
            textView.string = text
            coordinator.lastReportedText = text
            let length = (text as NSString).length
            if let selection, selection.isValid(in: text) {
                textView.setSelectedRange(NSRange(location: selection.start, length: selection.length))
            } else {
                let location = min(previous.location, length)
                textView.setSelectedRange(NSRange(location: location, length: 0))
            }
        }

        if isFocused, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeCommandTextView
        weak var textView: NSTextView?
        var lastReportedText = ""
        private var pendingEditRange: NSRange?
        private var pendingReplacement: String?

        init(_ parent: NativeCommandTextView) {
            self.parent = parent
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            pendingEditRange = affectedCharRange
            pendingReplacement = replacementString ?? ""
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let hasMarkedText = textView.hasMarkedText()
            parent.onMarkedTextChange(hasMarkedText)

            guard !hasMarkedText else {
                pendingEditRange = nil
                pendingReplacement = nil
                return
            }

            let edit: CommandEdit?
            if let range = pendingEditRange, let replacement = pendingReplacement {
                let selected = textView.selectedRange()
                edit = CommandEdit(
                    range: SourceSpan(start: range.location, end: range.location + range.length),
                    replacement: replacement,
                    resultingSelection: SourceSpan(
                        start: selected.location,
                        end: selected.location + selected.length
                    )
                )
            } else {
                edit = nil
            }

            pendingEditRange = nil
            pendingReplacement = nil
            lastReportedText = textView.string
            parent.onTextChange(textView.string, edit)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let range = textView.selectedRange()
            parent.onSelectionChange(
                SourceSpan(start: range.location, end: range.location + range.length)
            )
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.onFocusChange(true)
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.onFocusChange(false)
        }

        func textView(
            _ textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if textView.hasMarkedText() {
                return false
            }

            switch commandSelector {
            case #selector(NSResponder.moveUp(_:)):
                return parent.hasSuggestions() ? parent.onMoveHighlight(-1) : false
            case #selector(NSResponder.moveDown(_:)):
                return parent.hasSuggestions() ? parent.onMoveHighlight(1) : false
            case #selector(NSResponder.insertNewline(_:)):
                return parent.hasSuggestions() ? parent.onAcceptHighlighted() : false
            case #selector(NSResponder.insertTab(_:)):
                return parent.hasSuggestions() ? parent.onAcceptSelected() : false
            case #selector(NSResponder.cancelOperation(_:)):
                return parent.hasSuggestions() ? parent.onEscape() : false
            default:
                return false
            }
        }
    }
}
