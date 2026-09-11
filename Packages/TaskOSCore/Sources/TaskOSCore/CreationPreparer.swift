import Foundation

public struct CreationPreparer: Sendable {
    private let registry: CapabilityRegistry
    private let catalog: any ResourceCatalog
    private let permissions: any PermissionStatusProvider

    public init(
        registry: CapabilityRegistry = .standard,
        catalog: any ResourceCatalog,
        permissions: any PermissionStatusProvider
    ) {
        self.registry = registry
        self.catalog = catalog
        self.permissions = permissions
    }

    public func prepare(_ definition: AutomationDefinition) async -> WorkflowPreview {
        var issues = definition.validate().issues
        var actionPreviews: [ActionPreview] = []
        var requiredPermissions: Set<PermissionKind> = []

        for (index, action) in definition.actions.enumerated() {
            requiredPermissions.formUnion(action.requiredPermissions)

            switch action {
            case .openApplication(let configuration):
                let label = configuration.application.label
                if let application = await catalog.application(bundleIdentifier: configuration.application.identifier) {
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .openApplication,
                            title: title(for: .openApplication),
                            targetLabel: application.displayName,
                            status: .ready,
                            detail: nil
                        )
                    )
                } else {
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .openApplication,
                            title: title(for: .openApplication),
                            targetLabel: label,
                            status: .missingResource,
                            detail: "Not installed or unavailable."
                        )
                    )
                    issues.append(.error("Action \(index + 1): \(label) is not available on this Mac."))
                }

            case .openWebsite(let configuration):
                if let browser = configuration.browser,
                   await catalog.application(bundleIdentifier: browser.identifier) == nil {
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .openWebsite,
                            title: title(for: .openWebsite),
                            targetLabel: configuration.url,
                            status: .missingResource,
                            detail: "Browser not installed."
                        )
                    )
                    issues.append(.error("Action \(index + 1): \(browser.label) is not available on this Mac."))
                } else if OpenWebsiteAction.isAbsoluteHTTPURL(configuration.url) {
                    let target = configuration.browser.map { "\(configuration.url) in \($0.label)" } ?? configuration.url
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .openWebsite,
                            title: title(for: .openWebsite),
                            targetLabel: target,
                            status: .ready,
                            detail: nil
                        )
                    )
                } else {
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .openWebsite,
                            title: title(for: .openWebsite),
                            targetLabel: configuration.url,
                            status: .missingResource,
                            detail: "Not a valid web address."
                        )
                    )
                    issues.append(.error("Action \(index + 1): \(configuration.url) is not a valid web address."))
                }

            case .arrangeWindow(let configuration):
                let appLabel = configuration.application.label
                if let application = await catalog.application(bundleIdentifier: configuration.application.identifier) {
                    let state = await permissions.state(for: .accessibility)
                    switch state {
                    case .granted:
                        actionPreviews.append(
                            ActionPreview(
                                index: index,
                                actionID: .arrangeWindow,
                                title: title(for: .arrangeWindow),
                                targetLabel: "\(application.displayName) - \(configuration.preset.displayName)",
                                status: .ready,
                                detail: nil
                            )
                        )
                    case .notDetermined:
                        actionPreviews.append(
                            ActionPreview(
                                index: index,
                                actionID: .arrangeWindow,
                                title: title(for: .arrangeWindow),
                                targetLabel: application.displayName,
                                status: .needsPermission,
                                detail: "Accessibility permission will be requested when you test."
                            )
                        )
                    case .denied:
                        actionPreviews.append(
                            ActionPreview(
                                index: index,
                                actionID: .arrangeWindow,
                                title: title(for: .arrangeWindow),
                                targetLabel: application.displayName,
                                status: .needsPermission,
                                detail: "Accessibility is off for TaskOS."
                            )
                        )
                        issues.append(.error("Action \(index + 1): Accessibility permission is denied. Enable it in System Settings > Privacy & Security > Accessibility."))
                    }
                } else {
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .arrangeWindow,
                            title: title(for: .arrangeWindow),
                            targetLabel: appLabel,
                            status: .missingResource,
                            detail: "Not installed or unavailable."
                        )
                    )
                    issues.append(.error("Action \(index + 1): \(appLabel) is not available on this Mac."))
                }

            case .wait(let wait):
                actionPreviews.append(
                    ActionPreview(
                        index: index,
                        actionID: .wait,
                        title: title(for: .wait),
                        targetLabel: String(format: "%.1fs", wait.duration),
                        status: .ready,
                        detail: nil
                    )
                )

            case .copyText(let copy):
                actionPreviews.append(
                    ActionPreview(
                        index: index,
                        actionID: .copyText,
                        title: title(for: .copyText),
                        targetLabel: String(copy.text.prefix(40)),
                        status: .ready,
                        detail: "Replaces the clipboard contents."
                    )
                )

            case .showNotification:
                let state = await permissions.state(for: .notifications)
                switch state {
                case .granted:
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .showNotification,
                            title: title(for: .showNotification),
                            targetLabel: nil,
                            status: .ready,
                            detail: nil
                        )
                    )
                case .notDetermined:
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .showNotification,
                            title: title(for: .showNotification),
                            targetLabel: nil,
                            status: .needsPermission,
                            detail: "Permission will be requested when you test."
                        )
                    )
                case .denied:
                    actionPreviews.append(
                        ActionPreview(
                            index: index,
                            actionID: .showNotification,
                            title: title(for: .showNotification),
                            targetLabel: nil,
                            status: .needsPermission,
                            detail: "Notifications are off for TaskOS."
                        )
                    )
                    issues.append(.error("Action \(index + 1): Notification permission is denied. Enable it in System Settings > Notifications > TaskOS."))
                }
            }
        }

        return WorkflowPreview(
            automationID: definition.id,
            revision: definition.revision,
            name: definition.name,
            triggerTitle: title(for: definition.trigger.id),
            actions: actionPreviews,
            requiredPermissions: requiredPermissions,
            issues: issues,
            willRunAutomatically: definition.trigger.schedule != nil
        )
    }

    private func title(for id: ActionID) -> String {
        registry.descriptor(for: id)?.title ?? id.stableID
    }

    private func title(for id: TriggerID) -> String {
        registry.descriptor(for: id)?.title ?? id.stableID
    }
}
