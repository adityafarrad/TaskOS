import SwiftUI
import TaskOSCore

struct InspectorView: View {
    let model: ComposerViewModel
    let selection: EditorSelection

    var body: some View {
        Group {
            if selection.isTriggerSelected {
                content(
                    title: TriggerPresentation.title(for: model.triggerFamily),
                    symbol: TriggerPresentation.symbol(for: model.triggerFamily)
                ) {
                    TriggerConfigurationView(model: model)
                }
            } else if let id = selection.selectedStepID,
                      let action = model.actions.first(where: { $0.id == id }) {
                content(
                    title: ActionPresentation.title(for: action.draft),
                    symbol: ActionPresentation.symbol(for: action.draft)
                ) {
                    StepConfigurationView(action: action, model: model)
                }
            } else {
                TaskOSEmptyState(
                    systemImage: "sidebar.right",
                    title: "Nothing selected",
                    message: "Select a trigger or a step to edit its settings here."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func content<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder body: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaskOSSpacing.md) {
                HStack(spacing: TaskOSSpacing.xs) {
                    Image(systemName: symbol)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                }
                Divider()
                body()
                Spacer(minLength: TaskOSSpacing.lg)
            }
            .padding(TaskOSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
