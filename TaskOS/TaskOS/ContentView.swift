import SwiftUI
import TaskOSCore

struct ContentView: View {
    @State private var model = WalkingSliceViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(TaskOSInfo.displayName)
                    .font(.title2)
                Text("Walking slice: Manual to Open Safari, Wait 1s, Notify")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(model.isRunning ? "Running..." : "Run now") {
                    model.run()
                }
                .disabled(model.isRunning)

                Text("This runs for real.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GroupBox("Result") {
                switch model.state {
                case .idle:
                    Text("Not run yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .running:
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .finished(let record):
                    RunResultView(record: record)
                }
            }
        }
        .padding()
        .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
    }
}

private struct RunResultView: View {
    let record: RunRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(statusTitle)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2fs", record.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(record.actions, id: \.index) { item in
                HStack(spacing: 8) {
                    Image(systemName: symbol(for: item.outcome))
                        .foregroundStyle(color(for: item.outcome))
                    Text("\(item.index + 1). \(title(for: item.actionID))")
                    Spacer()
                    Text(detail(for: item.outcome))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusTitle: String {
        switch record.status {
        case .succeeded: return "Succeeded"
        case .failed: return "Failed"
        case .timedOut: return "Timed out"
        case .cancelled: return "Cancelled"
        }
    }

    private func title(for id: ActionID) -> String {
        switch id {
        case .openApplication: return "Open Application"
        case .wait: return "Wait"
        case .showNotification: return "Show Notification"
        }
    }

    private func symbol(for outcome: ActionOutcome) -> String {
        switch outcome {
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "xmark.octagon.fill"
        case .cancelled: return "slash.circle"
        case .notExecuted: return "circle.dashed"
        }
    }

    private func color(for outcome: ActionOutcome) -> Color {
        switch outcome {
        case .succeeded: return .green
        case .failed: return .red
        case .cancelled: return .orange
        case .notExecuted: return .gray
        }
    }

    private func detail(for outcome: ActionOutcome) -> String {
        switch outcome {
        case .succeeded: return "done"
        case .failed(let failure): return failure.message
        case .cancelled: return "cancelled"
        case .notExecuted: return "not executed"
        }
    }
}
