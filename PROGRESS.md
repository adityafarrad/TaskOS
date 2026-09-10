# TaskOS / MacFlow v1 — Progress Ledger

Source contract: `PLAN.md`.
Status legend: `not started` | `in progress` | `blocked` | `done`.

Solo, code-first execution. Phase 0 design/user-research work (0.1–0.3) is
compressed into implementation plus per-increment physical smoke checks.

## Delivery phases

### Phase 0 — Validate the experience and establish the foundation

| ID | Work package | Status | Evidence | Notes |
|---|---|---|---|---|
| 0.1 | Establish the product contract | compressed | PLAN.md as contract | Terminology + capability ledger folded into PLAN.md |
| 0.2 | Validate autocomplete with users | deferred | — | Solo code-first; revisit before composer sign-off (1.2) |
| 0.3 | Qualify platform risks | in progress | Increment A/B smoke checks | Folded into real implementation, one smoke check per increment |
| 0.4 | Establish the production skeleton | done | Increment A | git main tracks origin/main; macOS 14.0; Swift 6; TaskOSCore pkg + Swift Testing; purity test |
| 0.5 | Establish distribution access early | not started | — | Signing/notarization path deferred until there is an app to ship |

### Phase 1 — Deliver the first complete automation experience

| ID | Work package | Status | Evidence | Notes |
|---|---|---|---|---|
| 1.1 | Build the typed domain and registry | in progress | Increment B1 | Typed domain + registry + coding for 4 capabilities; persistence layer pending |
| 1.2 | Build the shared composer | in progress | Increments C1-C3 | Grammar, parser, spans, canonical phrases, suggestions, composer document done; UI pending |
| 1.3 | Build preparation, preview, and execution | done | Increments B2 + B3 | Effect-free preview, resource resolution, permissions, revision-bound approval, sequential execution with timeouts and cancellation |
| 1.4 | Prove the first complete workflow | not started | — | First reforecast milestone |
| 1.5 | Complete the basic product shell | not started | — | |

### Phase 2 — Complete everyday workflows and automatic execution

| ID | Work package | Status | Evidence | Notes |
|---|---|---|---|---|
| 2.1 | Add scheduling and runtime admission | not started | — | |
| 2.2 | Finish app, window, and utility actions | not started | — | |
| 2.3 | Add selected files and portable workflows | not started | — | |
| 2.4 | Add event-triggered workflows | not started | — | |
| 2.5 | Finish the template and discovery experience | not started | — | |
| 2.6 | Complete everyday management and recovery | not started | — | |

### Phase 3 — Qualify, beta-test, and distribute

| ID | Work package | Status | Evidence | Notes |
|---|---|---|---|---|
| 3.1 | Complete system validation | not started | — | |
| 3.2 | Run the physical compatibility matrix | not started | — | |
| 3.3 | Validate usability, accessibility, and performance | not started | — | |
| 3.4 | Conduct the beta | not started | — | |
| 3.5 | Finish distribution and updates | not started | — | |
| 3.6 | Freeze and release | not started | — | |

## Increment log

### Increment A — Foundation (plan 0.4)

- Status: done
- Scope: git repo based on `origin/main`; repo-local identity; `.gitignore`;
  `AGENTS.md`; `opencode.json`; macOS 14 + Swift 6 project settings;
  pure `TaskOSCore` Swift package with Swift Testing and a framework-purity
  test; injectable `CoreClock` + deterministic `TestClock`; app wired to Core
  and boots a minimal shell.
- Interfaces changed: added `TaskOSInfo` (displayName, coreVersion);
  added `CoreClock` protocol, `SystemClock`, and `Duration.timeInterval`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 4 tests, 2 suites, pass.
    Target platform reported `arm64e-apple-macos14.0`.
  - `xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration
    Debug build` — BUILD SUCCEEDED (Apple Development signed).
  - `xcodebuild ... -configuration Release build` — BUILD SUCCEEDED.
  - Verified: `MACOSX_DEPLOYMENT_TARGET = 14.0`, `SWIFT_VERSION = 6.0`
    (`EFFECTIVE_SWIFT_VERSION = 6`), `ARCHS = arm64 x86_64`,
    `ENABLE_HARDENED_RUNTIME = YES`; built binary `minos 14.0`.
  - Local package resolved by Xcode as `TaskOSCore ... @ local`.
- Physical checks: none yet (no runtime behavior in this increment).
- Remaining defects / gaps: fakes for resource catalog, event source, and
  executor deferred to Increment B because their Core protocols do not exist
  yet (avoiding speculative abstraction). Clock fake delivered.
- Next eligible work package: B1 (typed domain + registry for
  Manual / Open Application / Wait / Show Notification).

### Increment B1 — Typed domain and registry (plan 1.1, partial)

- Status: done
- Scope: stable capability IDs; typed trigger/action configurations for the
  walking-slice catalog (Manual, Open Application, Wait, Show Notification);
  typed `ResourceReference`; parameter validation; workflow revisions;
  `CapabilityRegistry` with consistency checks; versioned Codable envelope
  that rejects unknown future schemas and unknown capabilities.
- Interfaces changed: added `TriggerID`, `ActionID`, `ResourceReference`,
  `ManualTrigger`, `TriggerConfiguration`, `OpenApplicationAction`,
  `WaitAction`, `ShowNotificationAction`, `ActionConfiguration`,
  `ValidationIssue`, `ValidationResult`, `AutomationID`, `WorkflowRevision`,
  `AutomationDefinition`, `AutomationDraft`, `CapabilityDescriptor`,
  `CapabilityRegistry`, `PersistenceError`, `AutomationCoding`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 19 tests, 6 suites, pass.
    Covers registry consistency, validation bounds, draft-to-manual default,
    12-action limit, Codable round-trip preserving order, rejection of future
    schema versions, unknown capabilities, and malformed payloads.
  - `xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration
    Debug build` — BUILD SUCCEEDED.
- Physical checks: none (pure Core; no platform adapters or UI yet).
- Remaining defects / gaps:
  - Catalog is intentionally limited to 4 capabilities; Open Website and
    Arrange Window (plan 1.1) deferred to later increments.
  - Persistence is the pure-Core coding envelope only; the SwiftData
    repository behind an interface lands later in Phase 1.
  - No executor or adapter bindings yet (Increment B3).
- Next eligible work package: execution slice — `ActionExecutor` + platform
  adapters (plan 1.3 start), then sequential execution with timeouts and
  `RunRecord`, then the minimal Run UI. Registry surface (B2) and domain
  types (B1) are complete.

### Increment B2 — Execution slice (plan 1.3, partial)

- Status: done
- Behavior delivered: a real, user-visible Run path. Pressing "Run now" runs
  `Manual -> Open Application (Safari) -> Wait 1s -> Show Notification`
  through the production `WorkflowRunner` and native adapters, then shows the
  per-action result and overall status.
- Interfaces changed: added `ActionFailure`, `ActionOutcome`, `RunStatus`,
  `ActionRunRecord`, `RunRecord`, and the `ActionExecutor` protocol; added the
  `WorkflowRunner` actor with configurable `Timeouts`. App target added
  `OpenApplicationExecutor`, `NotificationExecutor`, `AppComposition`,
  `WalkingSliceViewModel`, and a Run UI in `ContentView`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 24 tests, 7 suites, pass.
    New coverage: ordered success with stop-on-first-failure, per-action
    timeout, cumulative-wait limit, injected-clock wait, and cancellation
    marking the in-flight action cancelled and later actions not executed.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
  - `xcodebuild ... Release build` — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Release app launched, stayed running.
  - Pressed "Run now": Safari opened/activated, the 1s wait elapsed, and the
    TaskOS notification "Safari is open." was delivered; UI reported the run.
- Remaining defects / gaps:
  - Preview, effect-free preflight, resource resolution, and revision-bound
    approval are not built yet (plan 1.3 remainder).
  - Whole-workflow timeout is enforced between actions, not as a hard deadline
    over a single long action.
  - No persistence of run history yet (in-memory `RunRecord` only).
  - Run is one-at-a-time via the UI guard; no queue/deduplication yet.
- Next eligible work package: plan 1.2 shared composer, or finish 1.3
  (preview + resolution + approval). Recommended next: preview/approval
  (1.3 remainder) to complete the reviewed, deliberate test path.

### Increment B3 — Preview, resolution, and approval (plan 1.3 completion)

- Status: done
- Behavior delivered: the app now reviews before it runs. Pressing "Preview"
  produces an effect-free plan showing each resolved step, the resolved
  application target, required permissions, and blocking issues. Testing is
  enabled only for a runnable revision that has been reviewed; changing the
  wait duration bumps the workflow revision, clears the preview, and disables
  testing until it is reviewed again.
- Interfaces changed: added `ApplicationResource`, `ResourceCatalog`,
  `PermissionKind`, `PermissionState`, `PermissionStatusProvider`,
  `ActionConfiguration.requiredPermissions`, `PreviewActionStatus`,
  `ActionPreview`, `WorkflowPreview`, `CreationPreparer`, and `ApprovalRegistry`.
  App target added `WorkspaceResourceCatalog`, `SystemPermissionStatusProvider`,
  and `ReviewViewModel`; `AppComposition` now owns the preparer and approvals;
  `ContentView` became the review/test UI.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 31 tests, 9 suites, pass.
    New coverage: installed vs missing application resolution, undetermined vs
    denied notification permission, non-runnable previews, preview identity and
    revision, and approval being invalidated by a revision change.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
  - `xcodebuild ... Release build` — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Preview produced the plan with no external effect (Safari did not open).
  - Test was disabled until a runnable revision had been previewed.
  - Changing the wait duration invalidated the preview and disabled testing.
  - Re-preview then Test opened Safari and delivered the notification; the run
    reported success. (User-confirmed; attached screenshots not machine-readable
    by the agent.)
- Remaining defects / gaps:
  - Preview is computed for the hardcoded walking-slice definition; it is not
    yet driven by a composer draft.
  - No persisted preview/approval or run history yet (in-memory only).
  - Accessibility permission plumbing exists in the model but no action
    requires it yet (window arrangement arrives in Phase 2).
- Next eligible work package: plan 1.2 (shared composer: grammar, text/cards,
  contextual suggestions) or plan 1.4 (canonical workflow end to end).
  Recommended next: plan 1.2 composer, since 1.3 is now complete.

### Increment C1 — Command grammar, parser, and canonical phrases (plan 1.2, partial)

- Status: done
- Behavior delivered: supported command text is recognized into structured
  clauses with source spans and diagnostics. The parser distinguishes
  complete, needs-input, unrecognized, and unsupported requests, keeps
  unrecognized/unsupported spans visible instead of dropping them, and can
  regenerate canonical phrasing from resolved actions.
- Interfaces changed: added `SourceSpan` (+ `String.substring(in:)`),
  `CommandToken`/`CommandTokenizer` (internal), `ParsedClauseKind`,
  `ParsedParameter`, `ParsedClause`, `ParseOutcome`, `ParseDiagnostic`,
  `ParsedCommand`, `CommandParser`, and `CanonicalPhrase`.
- Grammar covered: `open <app list>` (with `and`/comma-separated names),
  `wait [for] <number> [unit]`, `show a notification` / `notify`, connectors
  `and`/`then`/`also`/comma, an excluded-capability dictionary, and a fallback
  to unrecognized.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 46 tests, 11 suites,
    pass. New coverage: empty input, app recognition and spans, multi-resource
    lists, wait parsing (integer/fractional/out-of-range/missing), notification
    forms, multi-clause input, unsupported vs unrecognized classification, and
    canonical-phrase round-trip through the parser.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
- Physical checks: none (pure Core; no UI yet).
- Remaining defects / gaps:
  - No suggestion engine yet, no composer document, no native text editing,
    cards, undo/redo, draft autosave, or resource selection UI (plan 1.2
    remainder).
  - Grammar has no trigger productions yet (manual is implicit); scheduling,
    hotkey, and event triggers arrive in Phase 2.
  - Spans use character offsets; confirm UTF-16 alignment when wiring AppKit
    text editing.
- Next eligible work package: plan 1.2 remainder, starting with the contextual
  suggestion engine (Core), then the composer document with text/card sync and
  native text editing.

### Increment C2 — Contextual suggestion engine (plan 1.2, partial)

- Status: done
- Behavior delivered: deterministic, offline completion over the supported
  catalog and locally available applications. Suggestions adapt to the current
  context (empty field, `open`, `open <prefix>`, `wait`, `show`/`show a`) and
  are ranked grammar-position first, then exact, prefix, alias, and typo
  matches, with alphabetical tie-break and a visible-list limit of eight.
  Typo-tolerant results only surface as suggestions and are never selected
  automatically.
- Interfaces changed: added `Suggestion`, `SuggestionMatch`, and
  `SuggestionEngine`. Installed applications are injected as
  `[ApplicationResource]`, so the engine stays pure and deterministic; the app
  supplies them from `ResourceCatalog`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 57 tests, 12 suites,
    pass. New coverage: empty-field starters, `open` action + application
    suggestions, prefix match, exact match ranking, typo discovery, short
    prefixes excluded from typo search, eight-item limit, alphabetical
    tie-break, wait and notification contexts, and no suggestions for a
    completed `notify`.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
- Physical checks: none (pure Core; engine not yet wired to a UI).
- Remaining defects / gaps:
  - Engine uses the full installed-application list; incremental refresh and
    stale-result protection will be handled when wired to the live catalog.
  - No trigger or template suggestions yet (those capabilities arrive with
    Phase 2 and 2.5).
  - Plan section 2.2 keys/labels are not yet exposed for accessibility; that
    lands with the composer UI.
- Next eligible work package: plan 1.2 composer document with text/card sync,
  native text editing, resource selection, undo/redo, and draft autosave.

### Increment C3 — Composer document (plan 1.2, partial)

- Status: done
- Behavior delivered: one editing document holding command text, parsed clauses,
  ordered action drafts, and unresolved text spans. Typing reparses and rebuilds
  actions while preserving unresolved text; card edits regenerate only their
  clause via canonical phrasing; actions can be added, removed, moved, edited,
  and resolved; undo/redo cover typing and card edits; a definition is produced
  only when no unresolved text remains and every application is resolved.
- Interfaces changed: added `ComposerActionDraft`, `ComposerAction`,
  `ComposerElement`, and `ComposerDocument`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 67 tests, 13 suites,
    pass. New coverage: empty document, typing to actions, unsupported suffix
    retained and blocking definition, card edit preserving unresolved text,
    application resolution, action removal, undo/redo across typing and card
    edits, suggestion acceptance, and action reordering.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED (Core-only change).
- Physical checks: none (no UI yet).
- Remaining defects / gaps:
  - Reconciliation preserves action identity by order; inserting an action
    ahead of existing ones can reset stable card ids.
  - No persistence of drafts yet (in-memory document only).
  - No notification title/message fields in the UI yet.
- Next eligible work package: wire the composer document into a UI (text field,
  live suggestions, cards, resource picker, undo/redo) and connect to the
  existing review/test flow.
