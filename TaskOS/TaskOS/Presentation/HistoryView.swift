import SwiftUI
import TaskOSCore

struct HistoryView: View {
    let model: ComposerViewModel

    private var groupedRuns: [(day: Date, runs: [RunRecord])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: model.history) { calendar.startOfDay(for: $0.startedAt) }
        return groups.keys.sorted(by: >).map { day in
            (day, (groups[day] ?? []).sorted { $0.startedAt > $1.startedAt })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaskOSSpacing.lg) {
                header

                if model.history.isEmpty && model.admissionEvents.isEmpty {
                    TaskOSEmptyState(
                        systemImage: "clock.arrow.circlepath",
                        title: "No runs yet",
                        message: "Run a workflow and its results will appear here."
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    if !model.history.isEmpty {
                        runsTimeline
                    }
                    if !model.admissionEvents.isEmpty {
                        skippedSection
                    }
                }
            }
            .padding(.horizontal, TaskOSSpacing.xl)
            .padding(.vertical, TaskOSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("History")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xxs) {
            Text("History")
                .font(.title2.weight(.semibold))
            Text("Recent runs and automatic-trigger activity.")
                .foregroundStyle(.secondary)
        }
    }

    private var runsTimeline: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.md) {
            ForEach(groupedRuns, id: \.day) { group in
                VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
                    Text(dayLabel(group.day))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    VStack(spacing: TaskOSSpacing.xs) {
                        ForEach(group.runs) { run in
                            RunHistoryRow(run: run)
                        }
                    }
                }
            }
        }
    }

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            TaskOSSectionHeader("Skipped & queued events")
            VStack(spacing: 0) {
                ForEach(Array(model.admissionEvents.suffix(20).reversed().enumerated()), id: \.offset) { index, event in
                    HStack(spacing: TaskOSSpacing.sm) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(event.automationName)
                        Text(event.kind.displayName)
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(event.occurredAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, TaskOSSpacing.sm)

                    if index < model.admissionEvents.suffix(20).count - 1 {
                        Divider()
                    }
                }
            }
            .taskOSCard()
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct RunHistoryRow: View {
    let run: RunRecord

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
                ForEach(run.actions, id: \.index) { item in
                    HStack(spacing: TaskOSSpacing.xs) {
                        Image(systemName: RunPresentation.symbol(for: item.outcome))
                            .foregroundStyle(RunPresentation.tint(for: item.outcome))
                        Text("\(item.index + 1). \(ActionPresentation.title(for: item.actionID))")
                        Spacer()
                        Text(RunPresentation.detail(for: item.outcome))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, TaskOSSpacing.xxs)
        } label: {
            HStack(spacing: TaskOSSpacing.sm) {
                Image(systemName: RunPresentation.symbol(for: run.status))
                    .foregroundStyle(RunPresentation.tint(for: run.status))
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(run.automationName)
                        .lineLimit(1)
                    Text(run.startedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(RunPresentation.title(for: run.status))
                    .font(.caption)
                    .foregroundStyle(RunPresentation.tint(for: run.status))

                Text(String(format: "%.2fs", run.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .contentShape(Rectangle())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, TaskOSSpacing.sm)
        .taskOSCard()
    }
}
