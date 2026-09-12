import SwiftUI
import TaskOSCore

struct SidebarView: View {
    let model: ComposerViewModel
    @Binding var selection: SidebarSelection
    var compact: Bool = false
    var onSelect: (SidebarSelection) -> Void
    var onNewWorkflow: () -> Void

    private var sidebarMaxWidth: CGFloat? {
        compact ? 76 : nil
    }

    var body: some View {
        List {
            Section {
                destinationButton(.workflows)
                newWorkflowRow
                destinationButton(.templates)
                destinationButton(.history)
                destinationButton(.settings)
            } header: {
                brand
            } footer: {
                if !compact, model.automaticTriggersPaused {
                    Label("Automatic triggers are paused from the menu bar.", systemImage: "pause.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(
            min: compact ? 56 : TaskOSMetrics.sidebarMin,
            ideal: compact ? 64 : TaskOSMetrics.sidebarIdeal,
            max: sidebarMaxWidth
        )
    }

    private var brand: some View {
        HStack(spacing: TaskOSSpacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.gradient)
                Image(systemName: "command")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 24, height: 24)
            if !compact {
                Text(TaskOSInfo.displayName)
                    .font(.headline)
            }
        }
        .frame(maxWidth: compact ? .infinity : nil, alignment: compact ? .center : .leading)
        .padding(.vertical, 6)
        .textCase(nil)
    }

    private func isDestinationSelected(_ destination: SidebarDestination) -> Bool {
        selection == .destination(destination)
    }

    private func destinationButton(_ destination: SidebarDestination, badge: Int? = nil) -> some View {
        Button {
            onSelect(.destination(destination))
        } label: {
            if compact {
                Image(systemName: SidebarPresentation.symbol(for: destination))
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(Rectangle())
            } else {
                HStack(spacing: TaskOSSpacing.xs) {
                    Label(destination.title, systemImage: SidebarPresentation.symbol(for: destination))
                    Spacer(minLength: 0)
                    if let badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(rowBackground(isSelected: isDestinationSelected(destination)))
        .accessibilityAddTraits(isDestinationSelected(destination) ? [.isSelected] : [])
        .accessibilityLabel(destination.title)
        .accessibilityIdentifier("sidebar.\(destination.rawValue)")
    }

    @ViewBuilder
    private var newWorkflowRow: some View {
        Button {
            onNewWorkflow()
        } label: {
            if compact {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                    .frame(width: 28, height: 28)
                    .background(Color.primary, in: Circle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(Rectangle())
            } else {
                HStack(spacing: TaskOSSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("New")
                        .fontWeight(.semibold)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary, in: Capsule())
                .contentShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .help("New workflow (⌘N)")
        .accessibilityLabel("New workflow")
        .accessibilityIdentifier("sidebar.newWorkflow")
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.16))
                .padding(.horizontal, 4)
        } else {
            Color.clear
        }
    }
}
