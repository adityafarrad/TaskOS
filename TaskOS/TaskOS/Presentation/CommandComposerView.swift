import SwiftUI
import TaskOSCore

struct CommandComposerView: View {
    let model: ComposerViewModel
    @FocusState.Binding var isFocused: Bool
    var onBrowseActions: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var localText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            HStack(alignment: .top, spacing: TaskOSSpacing.sm) {
                Image(systemName: "command")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isFocused ? Color.accentColor : .secondary)
                    .padding(.top, 2)

                TextField(
                    "Describe what you want your Mac to do…",
                    text: $localText,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(2...6)
                .focused($isFocused)
                .accessibilityLabel("Automation command")
                .onAppear { localText = model.text }
                .onChange(of: localText) { _, newValue in
                    guard newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        != model.text.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                    model.setText(newValue)
                }
                .onChange(of: model.text) { _, newValue in
                    guard newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        != localText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                    localText = newValue
                }
                .onKeyPress(.upArrow) {
                    model.moveHighlight(by: -1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    model.moveHighlight(by: 1)
                    return .handled
                }
                .onKeyPress(.return) {
                    if !model.visibleSuggestions.isEmpty {
                        model.acceptHighlighted()
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.escape) {
                    model.dismissSuggestions()
                    return .handled
                }
            }

            if !model.visibleSuggestions.isEmpty {
                suggestionPanel
            }

            HStack(spacing: TaskOSSpacing.sm) {
                Button {
                    onBrowseActions()
                } label: {
                    Label("Browse supported actions", systemImage: "magnifyingglass")
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
    }

    private func suggestionAccessibilityLabel(_ suggestion: Suggestion) -> String {
        var parts = ["\(suggestion.title), \(suggestion.category.rawValue)"]
        if suggestion.requiresParameter {
            parts.append("needs more input")
        }
        return parts.joined(separator: ", ")
    }
}
