import SwiftUI
import TaskOSCore

struct CommandComposerView: View {
    let model: ComposerViewModel
    @FocusState.Binding var isFocused: Bool
    var onBrowseActions: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            HStack(alignment: .top, spacing: TaskOSSpacing.sm) {
                Image(systemName: "command")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isFocused ? Color.accentColor : .secondary)
                    .padding(.top, 2)

                NativeCommandTextView(
                    text: model.text,
                    isFocused: isFocused,
                    onTextChange: { value, edit in
                        model.updateFromEditor(text: value, edit: edit)
                    },
                    onSelectionChange: { span in
                        model.updateCommandSelection(span)
                    },
                    onMarkedTextChange: { active in
                        model.setMarkedTextActive(active)
                    },
                    onFocusChange: { focused in
                        isFocused = focused
                    },
                    onMoveHighlight: { delta in
                        model.moveHighlightInteractively(by: delta)
                    },
                    onAcceptHighlighted: {
                        model.acceptHighlightedInteractively()
                    },
                    onAcceptSelected: {
                        model.acceptSelectedInteractively()
                    },
                    onEscape: {
                        model.dismissSuggestionsInteractively()
                    },
                    hasSuggestions: {
                        !model.visibleSuggestions.isEmpty
                    }
                )
                .frame(minHeight: 40, maxHeight: 140)
                .accessibilityLabel("Automation command")
                .accessibilityIdentifier("composer.field")
            }

            if !model.visibleSuggestions.isEmpty {
                suggestionPanel
            }

            HStack(spacing: TaskOSSpacing.sm) {
                Button {
                    onBrowseActions()
                } label: {
                    Label("Browse actions & triggers", systemImage: "list.bullet.rectangle")
                        .font(.caption)
                }
                .buttonStyle(.link)

                Spacer()

                if !model.unresolvedTexts.isEmpty {
                    Label(
                        "Unresolved: \(model.unresolvedTexts.joined(separator: " / "))",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                }
            }
        }
        .padding(TaskOSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TaskOSRadius.composer, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TaskOSRadius.composer, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.accentColor : Color(nsColor: .separatorColor),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .animation(.taskOSQuick, value: isFocused)
    }

    private var suggestionPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(model.visibleSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button {
                    model.accept(suggestion)
                } label: {
                    HStack(spacing: TaskOSSpacing.xs) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text(suggestion.title)
                        Spacer()
                        if suggestion.requiresParameter {
                            TaskOSStatusChip(text: "needs input", tint: .orange)
                        }
                        Text(suggestion.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, TaskOSSpacing.xs)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    index == model.highlightedSuggestion
                        ? Color.accentColor.opacity(0.14)
                        : Color.clear
                )
                .accessibilityLabel(suggestionAccessibilityLabel(suggestion))
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
        .animation(reduceMotion ? nil : .taskOSQuick, value: model.visibleSuggestions.count)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.suggestionCountAccessibilityLabel)
        .accessibilityValue(model.selectedSuggestionAccessibilityLabel ?? "")
    }

    private func suggestionAccessibilityLabel(_ suggestion: Suggestion) -> String {
        var parts = ["\(suggestion.title), \(suggestion.category.rawValue)", suggestion.replacementMeaning]
        if suggestion.requiresParameter {
            parts.append("needs more input")
        }
        return parts.joined(separator: ", ")
    }
}
