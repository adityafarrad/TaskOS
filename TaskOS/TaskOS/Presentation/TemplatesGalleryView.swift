import SwiftUI
import TaskOSCore

struct TemplatesGalleryView: View {
    let model: ComposerViewModel
    let onUse: (AutomationTemplate) -> Void

    @State private var showAll = false

    private var templates: [AutomationTemplate] {
        TemplatePresentation.featured(model.filteredTemplates)
    }

    private var visibleTemplates: [AutomationTemplate] {
        showAll ? templates : Array(templates.prefix(6))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaskOSSpacing.lg) {
                header
                if visibleTemplates.isEmpty {
                    TaskOSEmptyState(
                        systemImage: "square.grid.2x2",
                        title: "No templates found",
                        message: "Try a different search term."
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 250, maximum: 360), spacing: TaskOSSpacing.sm)],
                        spacing: TaskOSSpacing.sm
                    ) {
                        ForEach(visibleTemplates) { template in
                            TemplateCard(template: template) {
                                onUse(template)
                            }
                        }
                    }

                    if !showAll, templates.count > 6 {
                        Button("View all templates") { withAnimation(.taskOSStandard) { showAll = true } }
                            .buttonStyle(.link)
                    }
                }
            }
            .padding(.horizontal, TaskOSSpacing.xl)
            .padding(.vertical, TaskOSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Templates")
        .accessibilityIdentifier("templates.view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
            Text("Start from a template")
                .font(.title2.weight(.semibold))
            Text("Curated workflows you can customize before saving.")
                .foregroundStyle(.secondary)
            HStack(spacing: TaskOSSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    "Search templates",
                    text: Binding(get: { model.templateSearch }, set: { model.templateSearch = $0 })
                )
                .textFieldStyle(.plain)
            }
            .padding(.horizontal, TaskOSSpacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                    .fill(.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TemplateCard: View {
    let template: AutomationTemplate
    let onUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            Image(systemName: TemplatePresentation.symbol(for: template.id))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(height: 26)

            Text(template.name)
                .font(.headline)
                .lineLimit(2)

            Text(template.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let limitations = template.limitations {
                Text(limitations)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Use", action: onUse)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(TaskOSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 184, alignment: .top)
        .taskOSCard()
    }
}
