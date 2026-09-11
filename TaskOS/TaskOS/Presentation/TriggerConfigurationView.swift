import SwiftUI
import TaskOSCore

struct TriggerConfigurationView: View {
    let model: ComposerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.md) {
            Picker(
                "Trigger",
                selection: Binding(get: { model.triggerFamily }, set: { model.setTriggerFamily($0) })
            ) {
                Text("Manual").tag(ComposerViewModel.TriggerFamily.manual)
                Text("Schedule").tag(ComposerViewModel.TriggerFamily.schedule)
                Text("App event").tag(ComposerViewModel.TriggerFamily.applicationLifecycle)
                Text("Mac wakes").tag(ComposerViewModel.TriggerFamily.wake)
                Text("Display").tag(ComposerViewModel.TriggerFamily.displayConnection)
                Text("Drive").tag(ComposerViewModel.TriggerFamily.externalVolume)
                Text("Power source").tag(ComposerViewModel.TriggerFamily.powerSource)
                Text("Battery").tag(ComposerViewModel.TriggerFamily.batteryThreshold)
            }

            configuration

            availability
        }
    }

    @ViewBuilder
    private var configuration: some View {
        if model.isScheduled {
            scheduleCard
        } else if model.isLifecycleTrigger {
            lifecycleCard
        } else if model.isWakeTrigger {
            Text("Runs after the Mac wakes, once the session is ready.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if model.isDisplayTrigger {
            displayCard
        } else if model.isVolumeTrigger {
            volumeCard
        } else if model.isPowerTrigger {
            powerCard
        } else if model.isBatteryTrigger {
            batteryCard
        } else {
            Text("Runs only when you start it from the app or menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var availability: some View {
        if model.isBatteryTrigger, !model.hardware.hasBattery {
            Label(
                "This Mac has no battery, so this trigger will not fire here.",
                systemImage: "exclamationmark.triangle"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        } else if model.isDisplayTrigger, !model.hardware.hasExternalDisplay {
            Label(
                "No external display is connected now; this fires when one connects.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if model.isVolumeTrigger, !model.hardware.hasRemovableVolume {
            Label(
                "No removable volume is mounted now; this fires when one mounts.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            Picker(
                "Repeat",
                selection: Binding(get: { model.triggerKind }, set: { model.setTriggerKind($0) })
            ) {
                Text("Daily").tag(ComposerViewModel.TriggerKind.daily)
                Text("Weekdays").tag(ComposerViewModel.TriggerKind.weekdays)
                Text("Interval").tag(ComposerViewModel.TriggerKind.interval)
                Text("Once").tag(ComposerViewModel.TriggerKind.once)
            }
            .pickerStyle(.segmented)

            switch model.triggerKind {
            case .daily:
                DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
            case .weekdays:
                weekdayPicker
                DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
            case .interval:
                Picker(
                    "Every",
                    selection: Binding(
                        get: { model.scheduleIntervalSeconds },
                        set: { model.setScheduleInterval($0) }
                    )
                ) {
                    ForEach(ComposerViewModel.intervalOptions, id: \.self) { seconds in
                        Text(intervalLabel(seconds)).tag(seconds)
                    }
                }
            case .once:
                DatePicker(
                    "Date and time",
                    selection: Binding(
                        get: { model.oneTimeDate },
                        set: { model.setOneTimeDate($0) }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            if !model.upcomingOccurrences.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next runs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(Array(model.upcomingOccurrences.enumerated()), id: \.offset) { _, date in
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var lifecycleCard: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            Picker("Application", selection: lifecycleApplicationBinding) {
                Text("Select…").tag("")
                ForEach(model.applications, id: \.bundleIdentifier) { application in
                    Text(application.displayName).tag(application.bundleIdentifier)
                }
            }

            Picker(
                "Event",
                selection: Binding(get: { model.lifecycleEvent }, set: { model.setLifecycleEvent($0) })
            ) {
                Text("opens").tag(LifecycleEvent.launched)
                Text("quits").tag(LifecycleEvent.quit)
            }
            .pickerStyle(.segmented)

            if model.lifecycleApplication == nil {
                Label("Choose an application to watch.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var lifecycleApplicationBinding: Binding<String> {
        Binding(
            get: { model.lifecycleApplication?.identifier ?? "" },
            set: { newValue in
                guard let application = model.applications.first(where: { $0.bundleIdentifier == newValue }) else {
                    return
                }
                model.setLifecycleApplication(application)
            }
        )
    }

    @ViewBuilder
    private var displayCard: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            Picker(
                "Display event",
                selection: Binding(get: { model.displayEvent }, set: { model.setDisplayEvent($0) })
            ) {
                Text("connects").tag(DisplayEvent.connected)
                Text("disconnects").tag(DisplayEvent.disconnected)
            }
            .pickerStyle(.segmented)

            Picker("Display", selection: displaySelectionBinding) {
                Text("Any external display").tag("any")
                ForEach(model.displays, id: \.identifier) { screen in
                    Text(screen.displayName).tag(screen.identifier)
                }
            }
        }
    }

    private var displaySelectionBinding: Binding<String> {
        Binding(
            get: {
                if case .display(let identifier, _) = model.displaySelection {
                    return identifier
                }
                return "any"
            },
            set: { newValue in
                if newValue == "any" {
                    model.setDisplaySelection(.anyExternal)
                } else if let screen = model.displays.first(where: { $0.identifier == newValue }) {
                    model.setDisplaySelection(.display(identifier: screen.identifier, label: screen.displayName))
                }
            }
        )
    }

    @ViewBuilder
    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            Picker(
                "Drive event",
                selection: Binding(get: { model.volumeEvent }, set: { model.setVolumeEvent($0) })
            ) {
                Text("mounts").tag(VolumeEvent.mounted)
                Text("unmounts").tag(VolumeEvent.unmounted)
            }
            .pickerStyle(.segmented)

            Text("Any external drive")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var powerCard: some View {
        Picker(
            "Power event",
            selection: Binding(get: { model.powerEvent }, set: { model.setPowerEvent($0) })
        ) {
            Text("switches to battery").tag(PowerEvent.toBattery)
            Text("connects to power").tag(PowerEvent.toExternalPower)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            Picker(
                "Battery event",
                selection: Binding(get: { model.batteryComparator }, set: { model.setBatteryComparator($0) })
            ) {
                Text("drops below").tag(ThresholdComparison.below)
                Text("rises above").tag(ThresholdComparison.above)
            }
            .pickerStyle(.segmented)

            Stepper(
                value: Binding(get: { model.batteryPercentage }, set: { model.setBatteryPercentage($0) }),
                in: 1...99
            ) {
                Text("\(model.batteryPercentage)%")
                    .monospacedDigit()
            }
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(get: { model.timeDate }, set: { model.setTimeDate($0) })
    }

    private var weekdayPicker: some View {
        HStack(spacing: 4) {
            ForEach(Weekday.allCases) { day in
                Button(String(day.displayName.prefix(3))) {
                    model.toggleWeekday(day)
                }
                .buttonStyle(.bordered)
                .tint(model.scheduleWeekdays.contains(day) ? .accentColor : .gray)
            }
        }
    }

    private func intervalLabel(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return "\(minutes) minutes"
    }
}
