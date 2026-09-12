import SwiftUI
import TaskOSCore

struct StepCardView: View {
    let index: Int
    let action: ComposerAction
    let model: ComposerViewModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    private var unresolved: Bool {
        ActionPresentation.isUnresolved(action.draft, missingFile: model.isMissingFile)
    }

    var body: some View {
        HStack(spacing: TaskOSSpacing.sm) {
            dragHandle
            stepBadge

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ActionPresentation.title(for: action.draft))
                        .font(.headline)
                    if unresolved {
                        TaskOSStatusChip(text: "Needs input", systemImage: "exclamationmark.triangle", tint: .orange)
                    }
                }
                Text(ActionPresentation.summary(for: action.draft, missingFile: model.isMissingFile))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Step \(index + 1), \(ActionPresentation.title(for: action.draft))")
            .accessibilityHint("Double-tap to configure this step")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onSelect() }

            Spacer(minLength: TaskOSSpacing.xs)

            if isHovered || isSelected {
                controls
                    .transition(.opacity)
            }
        }
        .padding(.vertical, TaskOSSpacing.xs)
        .padding(.horizontal, TaskOSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .taskOSCard(isSelected: isSelected, isHovered: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("step.card.\(index)")
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.tertiary)
            .frame(width: 18)
            .contentShape(Rectangle())
            .draggable(action.id.uuidString)
            .help("Drag to reorder")
            .accessibilityLabel("Reorder step")
    }

    private var stepBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ActionPresentation.tint(for: action.draft).opacity(0.14))
            Image(systemName: ActionPresentation.symbol(for: action.draft))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ActionPresentation.tint(for: action.draft))
        }
        .frame(width: 30, height: 30)
        .overlay(alignment: .bottomTrailing) {
            Text("\(index + 1)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(2)
                .background(.background, in: Circle())
                .offset(x: 4, y: 4)
        }
    }

    private var controls: some View {
        HStack(spacing: 2) {
            iconButton("arrow.up", help: "Move up", action: onMoveUp)
            iconButton("arrow.down", help: "Move down", action: onMoveDown)
            iconButton("plus.on.square", help: "Duplicate step", action: onDuplicate)
            iconButton("trash", help: "Delete step", action: onDelete)
        }
        .buttonStyle(.borderless)
    }

    private func iconButton(_ systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 22, height: 22)
        }
        .help(help)
        .accessibilityLabel(help)
    }
}
