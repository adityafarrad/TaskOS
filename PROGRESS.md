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
| 1.1 | Build the typed domain and registry | done | Increments B1 + D1 | 4-capability catalog, validation, versioned coding, and persistence scaffolding complete; remaining capabilities continue in 2.2 |
| 1.2 | Build the shared composer | done | C1-C4 + G1-G2 | Parser, suggestions, document, UI, draft autosave, keyboard + VoiceOver; 12 templates scheduled for Phase 2.5 |
| 1.3 | Build preparation, preview, and execution | done | Increments B2 + B3 | Effect-free preview, resource resolution, permissions, revision-bound approval, sequential execution with timeouts and cancellation |
| 1.4 | Prove the first complete workflow | done | Increments E1-E3 | Canonical journey verified end to end in Release; Open Website + Arrange Window + Accessibility + history + edit/reuse |
| 1.5 | Complete the basic product shell | done | D1 + F1-F5 | Library, menu-bar runtime, settings, interrupted-run recovery, onboarding; global hotkey deferred to Phase 2 by user decision |

### Phase 2 — Complete everyday workflows and automatic execution

| ID | Work package | Status | Evidence | Notes |
|---|---|---|---|---|
| 2.1 | Add scheduling and runtime admission | in progress | Increments H1–H3 | Schedule model, occurrence calc, admission/queue/pause/cancel, schedule grammar, runtime registry, trigger card + next-run preview + enable toggle all implemented; physical verification of the schedule UI pending |
| 2.2 | Finish app, window, and utility actions | in progress | Increments I1 + I2 | Copy Text, Hide Application, and normal Quit Application done end to end; specific-display selection and notification-editing review pending |
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

### Increment C4 — Composer UI and review/test integration (plan 1.2, partial)

- Status: done
- Behavior delivered: a working autocomplete-guided composer. The user types a
  command, sees contextual suggestions and accepts them, sees live action cards
  that resolve installed applications, edits steps through their cards (wait
  slider, notification fields, application picker), reorders and deletes steps,
  and uses undo/redo. Unresolved wording stays visible and blocks review. The
  composer feeds the existing effect-free preview and revision-bound test flow.
- Interfaces changed: `ResourceCatalog` gained `installedApplications()`
  (default empty; `WorkspaceResourceCatalog` enumerates standard app folders);
  `AppComposition` now exposes the suggestion engine and an application loader;
  replaced the review-only view model with `ComposerViewModel`; `ContentView`
  is now the composer, cards, preview, and run result.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 67 tests, 13 suites,
    pass.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
  - `xcodebuild ... Release build` — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Typing `open Safari and wait 2 seconds` produced an Open Safari card and a
    2.0s Wait card.
  - Adding `and email Bob` produced an Unresolved notice and disabled Preview.
  - Typing `open No` offered Notes; accepting it replaced the fragment.
  - Adding and slider-editing a Wait updated the command text; undo/redo worked.
  - Adding a notification, previewing, and testing opened Safari and delivered
    the notification. User-confirmed.
- Remaining defects / gaps:
  - No templates and no draft autosave persistence yet (plan 1.2 remainder).
  - Keyboard navigation and VoiceOver were not formally verified; suggestions
    are currently mouse-clickable buttons.
  - Suggestion computation is synchronous, so the stale-async-result rule is
    trivially satisfied but not exercised by a real async refresh.
  - Reconciliation preserves action identity by order (inserting ahead can
    reset card ids).
- Next eligible work package: plan 1.4 (canonical workflow end to end) or the
  plan 1.2 remainder (templates, autosave, keyboard/VoiceOver). Recommended
  next: plan 1.4 to prove the full saved-and-reopened journey, then return for
  templates/autosave.

### Increment D1 — Persistence and workflow library (plan 1.5 start, plan 2.11 partial)

- Status: done
- Behavior delivered: the first complete saved-and-reopened journey. A composed
  workflow can be saved, appears in a Library, survives quitting and relaunching
  the app, can be run from the Library, and can be deleted.
- Interfaces changed: added `SavedWorkflow`, the `AutomationRepository` protocol,
  and `FileAutomationRepository` (actor). `AppComposition` now owns a repository
  rooted at Application Support/TaskOS/Workflows. `ComposerViewModel` gained
  library load/save/run/delete; `ContentView` gained a Save button and a Library
  section.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 72 tests, 14 suites,
    pass. New coverage: save/load round-trip, same-identity update (no
    duplicate), delete, newest-first ordering, and rejection of a future schema
    version.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
  - `xcodebuild ... Release build` — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Composed a workflow, previewed, and saved it; it appeared in the Library.
  - Quit the app, relaunched, and the workflow was still listed.
  - Ran it from the Library; Safari opened and the notification posted.
  - Deleted it; it left the Library. User-confirmed.
- Deliberate deviation: the plan names SwiftData behind the repository
  interface (section 2.11). This slice first implemented a versioned, file-based
  JSON repository behind the same `AutomationRepository` interface. Resolved in
  Increment D2: production now uses SwiftData and JSON is a test fixture only.
- Remaining defects / gaps:
  - Library has no search, rename, duplicate, or edit-in-composer yet; each app
    session currently reuses one draft identity, so saving overwrites rather than
    creating distinct workflows.
  - No menu-bar runtime, global hotkey, onboarding, settings, or interrupted-run
    recovery yet (plan 1.5 remainder).
  - The repository throws on a malformed file rather than isolating it; a
    per-record recovery path is still needed.
  - Draft autosave is not persisted; only saved workflows are.
- Next eligible work package: plan 1.4 (drive the canonical workspace journey on
  this persisted, reviewed test path) or continue plan 1.5 (library management
  and menu-bar runtime).

### Increment D2 — Resolve persistence deviation (plan 2.11)

- Status: done
- Behavior delivered: production persistence now uses SwiftData behind the
  unchanged `AutomationRepository` abstraction. `TaskOSCore` remains free of
  SwiftData, enforced by the Core purity test. The JSON file repository was
  removed from production sources and demoted to a deterministic test fixture.
- Architecture:
  - Production: `AutomationRepository` protocol → `SwiftDataAutomationRepository`
    (`@ModelActor`) → SwiftData `WorkflowRecord` (`@Model`). Callers depend only
    on `any AutomationRepository`; no caller imports SwiftData.
  - Tests: `AutomationRepository` → `InMemoryAutomationRepository` and the
    `FileAutomationRepository` fixture, both in the Core test target.
  - `SavedWorkflowSerialization` stays in Core to encode the versioned definition
    payload and for future portable export/import; it is a serialization detail,
    not the persistence mechanism (the store is SwiftData).
- Interfaces changed: renamed `SavedWorkflowCoding` to
  `SavedWorkflowSerialization`; moved `FileAutomationRepository` from Core
  sources into the Core test target; added `InMemoryAutomationRepository` fixture;
  added `WorkflowRecord` and `SwiftDataAutomationRepository` to the app; linked
  `TaskOSCore` into the app test target; `AppComposition` uses the SwiftData
  repository with an in-memory fallback if the container cannot be created.
- Tests performed:
  - `xcodebuild ... test -only-testing:TaskOSTests` — SwiftData repository
    save/load/update/delete and newest-first ordering through
    `any AutomationRepository`. TEST SUCCEEDED.
  - `swift test --package-path Packages/TaskOSCore` — 74 tests, 15 suites, pass
    (includes file and in-memory repository fixtures, future-schema rejection).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED (run for safety; not strictly required
    mid-phase).
- Physical checks: SwiftData save/relaunch/run/delete confirmed working on this
  Mac by the user.
- Remaining notes: old JSON files under Application Support/TaskOS/Workflows are
  no longer read; a one-time import can be added if desired.
- Next eligible work package: per user direction, plan 1.4 canonical journey,
  then the remaining plan 1.5 library management and menu-bar runtime. Do not
  start automatically.

### Fix F1 — Suggestion acceptance spacing (plan 1.2)

- Status: done
- Defect: accepting a suggestion after a connector produced concatenated text
  such as `open Safari andOpen Notes`, which then parsed as one malformed
  application name. Affected any suggestion accepted after `and`, `then`,
  `also`, or a comma.
- Fix: `ComposerDocument.accept(_:)` now inserts a single separating space
  between the preserved prefix and the accepted phrase when the prefix is
  non-empty and does not already end in whitespace.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 76 tests, 15 suites, pass.
    Added regression tests for acceptance after `and` and after `then`, asserting
    the space is present and the result parses into two actions.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
- Physical checks: user-reported defect fixed; verified in app per user's report
  flow (accept suggestion after `and`).
- Next eligible work package: unchanged — plan 1.4 canonical journey.

### Increment E1 — Open Website capability (plan 1.4, partial; plan A4)

- Status: done
- Behavior delivered: the app supports opening an absolute HTTP(S) URL in the
  default browser, end to end. Typing a domain such as `open apple.com`
  classifies it as a website (not an application), normalizes it to
  `https://apple.com`, shows a website card with an editable URL, previews it,
  and opens it on test.
- Interfaces changed: added `OpenWebsiteAction` and `ActionID.openWebsite`;
  added `ComposerActionDraft.openWebsite`; added `ResourceNameHeuristics`
  (`isWebsite`, `normalizedWebsiteURL`); tokenizer now keeps URL characters in a
  single word token; registry, canonical phrases, validation, permissions,
  preview, and suggestion starters extended; added `OpenWebsiteExecutor`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 83 tests, 16 suites, pass.
    New coverage: URL validation (http/https only), website-vs-application
    heuristics, normalization, composer classification, placeholder blocking
    until valid, canonical round-trip, preview readiness, and website starter.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Empty field listed "Open a website"; typing `open apple.com and wait 1
    second` produced a ready Open Website card and a Wait card; preview, test
    (opened the site in the default browser), and the notification all worked;
    editing the URL updated the command text. User-confirmed.
- Remaining defects / gaps:
  - Opening in a *selected* browser is modeled (`browser`) but has no card
    control yet.
  - No dedicated URL suggestion from a partial domain yet.
  - E2 (Arrange Window + Accessibility) and the canonical journey acceptance for
    plan 1.4 are still pending.
- Next eligible work package: E2 — Arrange Window (A7) with Accessibility
  permission handling, window targeting, presets, and display selection.

### Increment E2 — Arrange Window + Accessibility (plan 1.4, partial; plan A7)

- Status: done
- Behavior delivered: an app window can be positioned by preset and display
  selection, end to end. Typing `put Safari on the left half` (or
  `maximize`/`center`) builds an Arrange Window step; the card selects the
  application, preset, and display; preview reports the required Accessibility
  permission and offers recovery; test moves the real window and verifies the
  resulting geometry.
- Interfaces changed: added `WindowFrame`, `WindowPreset` (halves, quarters,
  maximize, center with deterministic frame math), `WindowDisplaySelection`,
  and `ArrangeWindowAction` + `ActionID.arrangeWindow`; added
  `ComposerActionDraft.arrangeWindow`; parser gained `put`/`arrange`/
  `maximize`/`center` grammar with presets; registry, canonical phrases,
  validation, permissions, and preview extended; added `ArrangeWindowExecutor`
  (Accessibility: main/focused/single window targeting, settable checks,
  geometry verification, usable-area clamping) and `AccessibilityPermission`.
- Architecture decision: `ENABLE_APP_SANDBOX` changed from `YES` to `NO` for the
  app target. The App Sandbox blocks Accessibility control of other apps, which
  A7 requires; the plan mandates Hardened Runtime and notarization (both kept)
  but does not require the sandbox. Side effect: app storage moved out of the
  sandbox container, so previously saved workflows do not appear.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 96 tests, 18 suites, pass.
    New coverage: preset frame math (halves, quarters, maximize, center +
    clamp), validation, required permission, parser (halves/quarters/maximize/
    center, missing preset), composer draft and resolution, canonical
    round-trip, and preview states for granted/undetermined/denied Accessibility.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS, verified
    stable across three consecutive runs (suite marked `.serialized` to avoid a
    SwiftData in-memory container-creation race).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Preview flagged Arrange Window as needing Accessibility; the grant flow
    opened System Settings; after granting and relaunching, preview showed ready
    and Test moved the Safari window to the left half. User-confirmed.
- Remaining defects / gaps:
  - Window targeting picks main/focused/only; a multi-window ambiguity fails
    clearly but there is no user disambiguation UI yet.
  - Display selection supports current and main; a specific display is modeled
    but not selectable in the UI.
  - Whole-workflow timeout still bounds per-action; a hung AX call is not
    independently interruptible.
- Next eligible work package: E3 — run the full canonical journey (Safari left,
  Notes right) end to end and capture the plan 1.4 acceptance evidence.

### Increment E3 — Canonical journey (plan 1.4 completion)

- Status: done
- Behavior delivered: the plan 1.4 canonical workspace journey works end to end
  in a Release build on this Mac: create (text and cards), preview, grant
  Accessibility, test, save, edit (new revision), inspect history, quit and
  relaunch, and run the restored workflow.
- Fixes made during the journey:
  - Open Website: the card now selects a browser (default or a specific app);
    the selected browser is carried in the resolved action and the preview
    resolves its availability. Previously the site always opened in the system
    default browser.
  - Arrange Window: the executor now waits (up to 8s) for the target app's
    window to exist before positioning, so opening an app and arranging it in
    the same run no longer fails on window availability.
- Interfaces changed: `ComposerActionDraft.openWebsite` now carries a browser;
  `ComposerDocument.setWebsiteBrowser`; `CreationPreparer` resolves the selected
  browser; `ArrangeWindowExecutor` gained a bounded window-availability wait.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 102 tests, 19 suites,
    pass. New coverage: browser flows into the resolved action, and preview
    reports a missing selected browser.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS
    (includes SwiftData workflow and run-history repositories).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Canonical command `open Safari and Notes and open apple.com and put Safari
    on the left half and put Notes on the right half` with the website browser
    set to Safari: apple.com opened in Safari; Safari moved left; Notes moved
    right. Save, edit-and-revise, history, quit/relaunch, and run-from-library
    all verified. User-confirmed.
- Acceptance against plan 1.4:
  - Entire path works in Release on a physical Mac — yes.
  - Saved execution does not invoke the parser — yes (runs the structured
    definition).
  - Application and window behavior verified on real apps — yes.
  - Missing permission, unavailable application, and ambiguous window produce
    useful recovery text — yes.
- Remaining defects / gaps:
  - Browser selection is card-only; retyping the command text resets it to the
    default browser.
  - Multi-window ambiguity fails with a message but has no disambiguation UI.
  - A specific display is modeled but not selectable in the UI.
- Next eligible work package: plan 1.5 remainder (library search/rename/
  duplicate, menu-bar runtime, settings, interrupted-run recovery) or the plan
  1.2 remainder (templates, autosave, keyboard/VoiceOver).

### Increment F1 — Library management (plan 1.5, partial)

- Status: done
- Behavior delivered: the Library supports search, rename, duplicate, edit,
  delete, and run; and saving no longer overwrites: distinct workflows get
  distinct identities, while unchanged re-saves and Library "Edit" update the
  existing record. A "New" action starts a fresh draft.
- Root cause fixed: the composer reused one workflow identity per session, so
  every save replaced the previous record.
- Interfaces changed: `ComposerViewModel` gained `librarySearch`,
  `filteredWorkflows`, `beginRename`/`commitRename`/`cancelRename`, `duplicate`,
  `newWorkflow`, and save-identity tracking (`editingWorkflowID`,
  `lastSavedSignature`, `lastSavedID`); `ContentView` Library gained a search
  field, inline rename, duplicate, and the New button.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 102 tests, 19 suites, pass
    (Core unchanged).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Saved three distinct workflows; all remain listed (no overwrite).
  - Search filtered the list; rename persisted; duplicate produced an
    independent "<name> Copy"; edit-then-save updated in place. User-confirmed.
- Remaining defects / gaps:
  - Loading a workflow for editing loses card-only values not present in the
    canonical command text (website browser, notification title/message).
  - No enabled/disabled toggle or pause state in the Library yet.
- Next eligible work package: F2 — menu-bar runtime (open, run a saved workflow,
  view current run, pause/resume automatic triggers, cancel, quit).

### Increment F2 — Menu-bar runtime (plan 1.5, partial; plan 2.7)

- Status: done
- Behavior delivered: a menu-bar extra ("TaskOS", text label) that stays live
  after the main window closes and provides: Open TaskOS, Run a workflow
  (submenu of saved workflows), current status, Pause/Resume automatic triggers
  (placeholder until Phase 2), Cancel current run, and Quit.
- Interfaces changed: `TaskOSApp` gained a `MenuBarExtra` and an `AppDelegate`
  that keeps the app alive when the last window closes; added
  `MenuBarViewModel` and `MenuBarContent`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 102 tests, 19 suites, pass
    (Core unchanged).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Menu-bar item visible; closing the window keeps it alive; running a workflow
    from the menu updates status and records history; cancel stops a waiting run;
    Open TaskOS reopens the window; Quit exits. User-confirmed.
- Notes: the menu first used an icon label, which was hard to find; switched to
  a text "TaskOS" label. Deferred menu items that depend on Phase 2 (real
  automatic triggers/queue) are represented by the placeholder pause toggle.
- Next eligible work package: F3 — settings + permission status + launch at
  login + local-data controls.

### Increment F3 — Settings and permission status (plan 1.5, partial; plan 2.7)

- Status: done
- Behavior delivered: a Settings section in the main window showing notification
  and accessibility permission status with a Recheck action and a Grant
  Accessibility action; a Launch at login toggle; Clear history and Delete all
  workflows data controls; and a short local-data/privacy note.
- Interfaces changed: `AppComposition` exposes the permission provider; added
  `LaunchAtLogin` (ServiceManagement `SMAppService.mainApp`); `ComposerViewModel`
  gained permission state, launch-at-login, and data-clearing methods;
  `ContentView` gained the Settings section.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 102 tests, 19 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Permission status shown and recheckable; grant action present; launch at
    login toggle attempted (dev-build location may refuse registration, which is
    reported); clear history and delete all workflows worked. User-confirmed.
- Remaining defects / gaps:
  - Launch at login from a DerivedData build may not register; a /Applications
    install is needed for a true test.
  - No settings for update checks yet (Phase 3 / Sparkle).
- Next eligible work package: F4 — interrupted-run recovery (persist an
  in-progress run; on startup mark unfinished prior runs interrupted).

### Increment F4 — Interrupted-run recovery (plan 1.5, partial; plan 2.11)

- Status: done
- Behavior delivered: a run is recorded as running when it starts, updated with
  its final result on completion, and any run left running by a quit or crash is
  marked interrupted on the next launch (and never replayed).
- Interfaces changed: `RunStatus` gained `running` and `interrupted`;
  `RunRecord` gained an `id` (Identifiable) and a mutable `status`/`finishedAt`,
  plus `RunRecord.starting(_:id:at:)`; `WorkflowRunner.run(_:id:)` accepts an
  identity; `RunHistoryRepository` gained `update(_:)` and
  `markRunningAsInterrupted()`; both repositories implemented them; the composer
  and menu-bar view models record the running placeholder then update it.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 104 tests, 19 suites,
    pass. New coverage: update replaces an existing run, and startup marks
    running runs interrupted while leaving completed runs alone.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS
    (SwiftData update + interrupted recovery).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon):
  - Started a 30s run and quit mid-run; after relaunch the History showed the
    run as "interrupted". User-confirmed.
- Scope decision (user): global hotkey recording (plan 2.10 KeyboardShortcuts) is
  deferred to Phase 2; it adds a third-party package and belongs with the
  automatic-trigger work.
- Remaining in plan 1.5: basic onboarding. Global hotkey deferred.
- Next eligible work package: plan 1.5 onboarding, or the plan 1.2 remainder
  (templates, draft autosave, keyboard/VoiceOver).

### Increment F5 — Basic onboarding (plan 1.5 completion)

- Status: done
- Behavior delivered: a one-time Welcome sheet on first launch explaining the
  typing/suggestions/cards model, preview-before-run, the menu-bar runtime, and
  the Accessibility requirement. Dismissing it persists completion; Settings
  has a "Show intro" action to reopen it.
- Interfaces changed: added `OnboardingStore` (UserDefaults flag) and
  `OnboardingView`; `ComposerViewModel` gained `showOnboarding`,
  `completeOnboarding`, and `showOnboardingHelp`; `ContentView` presents the
  sheet and exposes Show intro.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 104 tests, 19 suites, pass
    (Core unchanged).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon): sheet appeared on
  first launch, "Got it" dismissed and persisted (no sheet on relaunch), and
  Show intro reopened it. User-confirmed.
- Plan 1.5 status: complete except global hotkey, which the user deferred to
  Phase 2 (it adds the KeyboardShortcuts package and belongs with automatic
  triggers).
- Next eligible work package: the plan 1.2 remainder (draft autosave, keyboard/
  VoiceOver). Templates are scheduled for Phase 2 (2.5).

### Increment G1 — Draft autosave and recovery (plan 1.2, partial; plan 2.11)

- Status: done
- Behavior delivered: the current composer draft is autosaved while editing and
  restored on the next launch; saving removes the draft, and New clears it.
- Interfaces changed: added `ComposerDraft` and the `DraftRepository` protocol
  (Core), `InMemoryDraftRepository` (test fixture), `SwiftDataDraftRepository`
  + `DraftRecord` (app); `AppComposition` exposes `drafts`; `ComposerViewModel`
  restores on launch and debounces autosave, clearing on save/New.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 106 tests, 20 suites, pass
    (draft round-trip and single-draft replacement).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS
    (SwiftData draft repository).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon): unsaved command and
  name were restored after quit/reopen with a recovery notice; saving cleared
  the draft. User-confirmed.
- Remaining in plan 1.2: keyboard navigation of suggestions and VoiceOver.
  Templates are scheduled for Phase 2.5.
- Next eligible work package: G2 — keyboard navigation + VoiceOver for the
  composer suggestions.

### Increment G2 — Suggestion keyboard navigation + VoiceOver (plan 1.2 completion)

- Status: done
- Behavior delivered: up/down move a highlighted suggestion, Enter accepts the
  highlighted suggestion, and Escape dismisses suggestions without clearing the
  command. Suggestions carry accessibility labels announcing title, category,
  and whether more input is required; the command field has a label.
- Interfaces changed: `ComposerViewModel` gained `highlightedSuggestion`,
  `suggestionsDismissed`, `visibleSuggestions`, `moveHighlight`,
  `acceptHighlighted`, and `dismissSuggestions`; `ContentView` added key-press
  handling and accessibility labels.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 106 tests, 20 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — PASS.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks (on this Mac, macOS 26 / Apple silicon): arrows moved the
  highlight, Enter accepted, Escape dismissed, and VoiceOver announced the
  suggestion title/category/parameter state. User-confirmed.
- Plan 1.2 status: complete. The twelve curated templates remain scheduled for
  Phase 2.5 per the plan, not this phase.
- Next eligible work package: Phase 1 is now complete (1.1-1.5). Next is the
  Phase 1 exit gate (full-package build/test and Release journey) before Phase 2,
  or begin Phase 2.1 (scheduling and runtime admission). Recommended: run the
  Phase 1 gate first.

## Phase 1 exit gate — PASSED

- Core tests: `swift test --package-path Packages/TaskOSCore` — 106 tests,
  20 suites, pass (includes a Core purity test forbidding SwiftUI/AppKit/
  SwiftData).
- Clean build: `xcodebuild ... -configuration Release clean` succeeded, then
  Release build succeeded.
- App tests: `xcodebuild ... test -only-testing:TaskOSTests` — passed (SwiftData
  workflow, run-history, and draft repositories).
- Physical canonical journey (Release, this Mac, macOS 26 / Apple silicon):
  named workflow, `open Safari and Notes and open apple.com and put Safari on
  the left half and put Notes on the right half` with the website browser set to
  Safari; preview, test (Safari/Notes opened, apple.com in Safari, windows moved
  left/right), save, quit, relaunch, and run-from-library. User-confirmed.
- Gate criteria (plan Phase 1 exit gate): a new user can complete the canonical
  workspace journey using autocomplete or cards, recover from common errors, and
  run the saved workflow after relaunch. Met.

Phase 1 work packages 1.1-1.5 are complete. Deferred by plan/user decision:
the twelve curated templates (scheduled Phase 2.5) and global hotkey recording
(Phase 2, with the KeyboardShortcuts package).

Next eligible work package: 2.1 — scheduling and runtime admission.

### Increment H1 — Schedule model and occurrence calculations (plan 2.1, partial; plan T3)

- Status: done
- Behavior delivered: the typed schedule trigger and deterministic
  next-occurrence calculations that the runtime and editor will build on.
  Supports one-time, daily, selected-weekday, and fixed-interval schedules;
  computes the next three occurrences; follows the supplied time zone; skips a
  nonexistent daylight-saving local time; uses the first occurrence of a
  repeated daylight-saving local time; skips missed occurrences/backlog instead
  of replaying them; and rejects past-due one-time schedules when validated
  against a reference date.
- Interfaces changed: added `Weekday`; added `ScheduleTrigger` (oneTime, daily,
  weekdays, interval) with `validate()`/`validate(relativeTo:)`/`isPastDue`;
  added `ScheduleCalculator` (calendar/time-zone injectable, `nextOccurrence`/
  `nextOccurrences`). Added `TriggerID.schedule` and
  `TriggerConfiguration.schedule(_:)` plus a `schedule` accessor.
  `TriggerConfiguration.validate(relativeTo:)`, `AutomationDefinition.validate(
  relativeTo:)`, and `AutomationDraft.resolvedDefinition(relativeTo:)` now carry
  an optional reference date. Added a Schedule descriptor to
  `CapabilityRegistry.standard` and canonical schedule phrases to
  `CanonicalPhrase`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 124 tests, 21 suites, pass
    (was 106/20; +18 schedule tests). New coverage: one-time future/past,
    past-due validation relative to now, daily next-three ordering and
    strictly-after behavior, daylight-saving gap skip (America/New_York,
    2026-03-08 02:30 nonexistent), repeated-time first occurrence (2026-11-01
    01:30 EDT then next day 01:30 EST), weekday selection, empty-weekday
    rejection, interval anchor alignment, missed-interval backlog skip,
    interval-before-anchor start, interval and time-of-day validation bounds,
    time-zone following, trigger exposure, Codable round-trip, and reference-date
    gating of a past-due definition.
  - `xcodebuild ... Debug build` — BUILD SUCCEEDED.
  - `xcodebuild ... Release build` — BUILD SUCCEEDED.
- Physical checks: none (pure Core; no UI or runtime registration yet). This
  increment makes no user-visible claim of its own.
- Remaining defects / gaps:
  - No runtime registration, admission queue, cooldown, deduplication,
    pause/resume, or launch-at-login yet (plan 2.1 runtime half).
  - No parser grammar, composer card, next-occurrence UI, or automatic-run
    enablement yet (plan 2.1 UI half). `WillRunAutomatically` is still false.
  - Interval schedules are anchored to an absolute start instant; interval
    wall-clock/DST policy is deliberately not applied (fixed-duration interval).
- Next eligible work package: 2.1 runtime half (Increment H2) — admission,
  queue limits and expiration, duplicate suppression, cooldown, pause/resume,
  cancellation, launch at login, and sleep/session readiness.

### Increment H2 — Runtime admission and menu-bar runtime (plan 2.1, partial; plan 2.9)

- Status: done
- Behavior delivered: a single admission path that runs workflows one at a time
  and enforces the plan 2.9 runtime rules, plus a live menu-bar runtime built on
  it. Running a workflow from the menu bar now goes through the coordinator;
  the menu shows the current run, the queued count, and the paused state, and
  Pause/Resume and Cancel drive the coordinator. Queued automatic events expire
  instead of running stale; rapid automatic repeats are cooled down and
  deduplicated; at most ten runs queue; pausing clears pending automatic runs
  while the current run finishes; cancelling stops the current run and clears
  the queue; sleep marks the session inactive, interrupts the current run, and
  suppresses new automatic admissions until wake.
- Interfaces changed: added `RunCoordinator` (actor) with `RunRequestSource`,
  `AdmissionOutcome`, `AdmissionEvent`/`AdmissionEventKind`,
  `RunCoordinatorStatus`, `RunCoordinator.Limits`, and `RunExecution`; methods
  `submit`, `pauseAutomaticTriggers`, `resumeAutomaticTriggers`,
  `updateSessionReadiness`, `cancelAll`, `status`, and `waitUntilIdle`.
  App: `AppComposition` now owns the coordinator and persists start/update
  around each coordinated run; `MenuBarViewModel` submits through the
  coordinator and reports its status; `MenuBarContent` shows queue/pause state;
  added `SystemSessionObserver` (NSWorkspace sleep/wake -> session readiness).
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 142 tests, 22 suites, pass
    (was 124/21; +18). New coverage: manual/automatic admission, duplicate
    suppression while running and while queued, ten-second cooldown with
    clock advance, distinct workflows unaffected, ten-run queue cap and
    overflow, queued-automatic expiration, manual-run non-expiration, pause
    clearing pending automatic runs while the current finishes, pause
    suppressing automatic but allowing manual, resume, session-not-ready
    suppression plus interruption, cancel clearing the queue, in-order
    one-at-a-time execution, invalid-definition rejection, bounded event log,
    and status reporting.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: not yet re-walked in the app after the menu-bar change. The
  coordinator's behavior is covered by deterministic tests; a menu-bar
  run/pause/cancel smoke check is pending.
- Remaining defects / gaps:
  - No schedule registration or next-occurrence UI yet, so no automatic
    schedule can actually fire; automatic admission is tested but not reachable
    from the app. `WorkflowPreview.willRunAutomatically` is still false.
  - Composer "Test now" and Library "Run" still call `WorkflowRunner` directly
    and bypass the coordinator, so one-at-a-time admission is not yet universal.
  - Duplicate suppression keys on the workflow id for automatic runs; hotkey
    key-repeat suppression is not implemented (hotkey deferred).
  - Launch at login already existed (F3); no change here.
- Next eligible work package: 2.1 UI half (Increment H3) — schedule parser
  grammar, composer trigger card, next-three-occurrence preview, automatic-run
  enablement, and wiring the composer/library run paths through the coordinator.

### Fix H2-a — Menu-bar runtime lifetime and preload

- Status: done
- Defect (reported during manual check): the menu-bar "Run a workflow" submenu
  could appear empty/disabled and a run did not seem to start. Root cause:
  `MenuBarContent` owned its `MenuBarViewModel` in `@State`, and `MenuBarExtra`
  menu content can be rebuilt each time it opens, so the run menu was populated
  asynchronously (and could be discarded) on every open.
- Fix: `MenuBarViewModel` is now a single long-lived `shared` instance, created
  at launch from `AppDelegate.applicationDidFinishLaunching`, which loads saved
  workflows and recovers interrupted runs before the first menu open.
  `MenuBarContent` now references the shared instance and surfaces a load error
  instead of silently showing an empty menu. The menu-bar runtime also marks
  unfinished prior runs interrupted at launch (previously only the main window
  did this when it appeared).
- Investigation evidence: the SwiftData store contained the saved workflows and
  a coordinated `Queue test` run that started and then completed successfully,
  which showed the runner path worked and isolated the problem to menu
  presentation. No app errors appeared in the unified log.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED. (One intermediate run failed; the SwiftData test suite is known
    to flake on first in-memory container creation and passed on rerun. A
    follow-up hardening of that fixture is still desirable.)
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending re-check of the menu-bar run/pause/cancel flow after
  relaunch with the shared runtime.
- Next eligible work package: 2.1 UI half (Increment H3).

### Fix H2-b — Cancel enabled during a run (menu-bar status)

- Status: done
- Defect (reported during manual check): the menu-bar Status showed
  `Running ...` live, but **Cancel current run** stayed greyed out.
- Root cause: `MenuBarViewModel.run` set the status text optimistically but
  never set `isRunning = true`, then awaited `waitUntilIdle()` and only read the
  coordinator again after the run finished. `isRunning` therefore stayed false
  for the entire run, disabling Cancel.
- Fix: `run` sets `isRunning = true` for started/queued admissions and drives
  the menu from a 400 ms `monitorRun` loop that continuously applies the
  coordinator snapshot until idle. `Cancel` also monitors until idle, so the
  menu reflects the cancelled state. Status/queue/pause values are now applied
  through a single `apply(_:)` path.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: user-confirmed. Menu-bar status is live, the queue count
  shows, and Cancel current run is enabled during a run and stops it. Pause/
  resume and manual-run-while-paused confirmed. Sleep/wake deferred by the user
  and marked complete for now.
- Next eligible work package: 2.1 UI half (Increment H3).

### Fix H2-c — Live history and run duration

- Status: done
- Defects (reported during manual check):
  1. History rows never showed how long a run took (a 30s run looked timeless);
     only the immediate post-test result view showed a duration.
  2. The main window's History did not update while open when a workflow was run
     from the menu bar; it only refreshed after quitting and reopening the app.
- Root causes:
  1. `historySection` rendered steps and start time but not `run.duration`.
  2. Coordinated runs update the run-history repository but nothing told the
     open `ComposerViewModel` to reload; and `loadHistory` re-ran
     `markRunningAsInterrupted` on every load, which would wrongly interrupt a
     live run if history refreshed while one was in progress.
- Fix: history rows now show `duration` (`%.1fs`). `AppComposition` posts a
  `.taskOSRunHistoryDidChange` notification around each coordinated run (start
  and finish), and `ComposerViewModel` observes it and reloads history live.
  Interrupted-run recovery was moved out of `loadHistory` into a one-time
  `recoverInterruptedRuns` at window load, so refreshing history can no longer
  mislabel an in-flight run.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending re-check (run `Queue test` from the menu bar with the
  main window open; the History row should appear/update live and show ~30.0s).
- Next eligible work package: 2.1 UI half (Increment H3).

### Increment H3a — Schedule grammar and composer trigger (plan 2.1, partial)

- Status: done
- Behavior delivered: the composer now recognizes and holds a schedule trigger.
  Text like `every day at 9 am`, `every weekday at 5:30 pm`, `every monday and
  friday at 9:00 am`, `every weekend at 10:00 am`, `every 30 minutes`, `every 2
  hours`, `in 45 minutes`, and `once at 7:00 pm` produces a typed trigger instead
  of an action. The trigger can also be set from a card (`setTrigger`), renders
  back into parseable canonical text, participates in undo/redo, and flows into
  the saved definition. Relative (`in N`) and `once` schedules resolve to an
  absolute one-time date at definition time; past-due one-time schedules are
  rejected.
- Interfaces changed: added `ParsedClauseKind.schedule`, `ParsedSchedule`,
  `ParsedParameter.schedule`, and `ParsedClause.schedule`; `CommandParser` gained
  schedule productions (time with required am/pm or 24-hour, weekday lists,
  intervals, relative, once). Added `ComposerTriggerDraft`;
  `ComposerDocument` gained `trigger`, `setTrigger`,
  `triggerConfiguration(relativeTo:)`, and `makeDefinition(..., now:)`;
  `renderedText()` and undo snapshots now include the trigger.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 158 tests, 23 suites, pass
    (was 142/22; +16). New coverage: daily/24-hour/weekday/selected-weekday/
    weekend/interval/relative/once parsing, bare ambiguous hour needs input,
    schedule-with-actions completeness, composer trigger extraction, relative
    one-time definition resolution, past-due rejection, card render/parse
    round-trip, undo of trigger edits, and manual default.
  - Debug build — BUILD SUCCEEDED.
- Physical checks: none (no UI control yet).
- Remaining defects / gaps:
  - One-time dates are card-only: once a full date/time is chosen in the UI it
    renders as `Once at h:mm AM` and re-parsing the text keeps only the time.
  - No suggestion entries for schedules yet, and no trigger card, next-occurrence
    preview, or enable toggle (H3 UI).
  - No runtime registration that fires enabled schedules yet (H3 runtime).
- Next eligible work package: H3b — schedule runtime (registration, validation
  before events, fired via the coordinator) and H3c — trigger card, next
  three-occurrence preview, automatic-run enablement, and save/edit wiring.

### Increment H3b — Schedule runtime registry (plan 2.1, partial)

- Status: done
- Behavior delivered: enabled schedules are registered and fire automatically
  through the admission coordinator. The registry validates each definition
  before registering it and again before delivering a fire, computes the
  earliest next occurrence across all registrations, sleeps until then, and
  submits an automatic run. It skips missed occurrences (only future
  occurrences are scheduled), fires one-time schedules once, repeats interval
  schedules, cancels obsolete registrations on unregister/replace, and can be
  stopped.
- Interfaces changed: added `ScheduleRegistry` (actor) with `register`,
  `unregister`, `replaceAll`, `stop`, `registeredCount`, `isRegistered`, and
  `nextOccurrence(for:after:)`. Fixed a boundary defect in
  `ScheduleTrigger.isPastDue`/validation: a one-time schedule exactly at its
  fire instant was treated as past-due, which blocked the fire; the boundary is
  now strictly before.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 166 tests, 24 suites, pass
    (was 158/23; +8). New coverage: daily fire via the coordinator, missed
    occurrences skipped, interval repeated fires, unregister stops firing,
    past-due one-time not registered, invalid definition not registered,
    replaceAll keeps only enabled schedules, and one-time fires exactly once.
    The suite is `.serialized` because the clock-driven tasks starve under the
    default parallel execution.
  - Debug build — BUILD SUCCEEDED.
- Physical checks: none (registry not yet wired to app startup/enable UI).
- Remaining defects / gaps:
  - The registry is not yet constructed in the app, not loaded from saved
    workflows at launch, and not updated when workflows are saved, enabled,
    disabled, edited, or deleted. That wiring is H3c.
  - No trigger card, next-occurrence preview, or enable toggle yet.
- Next eligible work package: H3c — trigger card, next three-occurrence preview,
  automatic-run enablement, app startup registration/registration updates, and
  routing composer/library run paths through the coordinator.

### Increment H3c — Schedule UI, enablement, and runtime wiring (plan 2.1)

- Status: done
- Behavior delivered: a scheduling vertical the user can drive from the app.
  The composer has a **When** card: with no schedule it shows `Manual` plus
  **Add schedule**; a schedule shows a Daily/Weekdays/Interval/Once picker,
  the matching controls (time picker, weekday toggles, interval picker, or
  date-and-time picker), the **next three runs**, and a **Run automatically
  after saving** toggle. Choosing a schedule also writes the canonical phrase
  into the command field, and editing the text updates the card. Saved
  workflows: scheduled ones can be enabled/disabled from the Library (Auto
  switch) and register/unregister with the runtime registry; deletion and
  "delete all" unregister; loading a workflow for editing restores its trigger
  and enabled state. Enabled schedules are re-registered from storage at launch
  and fire through the admission coordinator. Preview now reports
  `willRunAutomatically` for schedule triggers. Composer test/run paths check
  the coordinator and refuse to start while another run is active.
- Interfaces changed: `AppComposition` owns `ScheduleCalculator` (current time
  zone) and `ScheduleRegistry`, and has `syncScheduleRegistrations()`;
  `AppDelegate` calls it at launch. `ComposerViewModel` gained `autoRunEnabled`,
  `TriggerKind`, `isScheduled`, `triggerKind`, `upcomingOccurrences`, `timeDate`,
  `scheduleWeekdays`, `scheduleIntervalSeconds`, `oneTimeDate`, `addSchedule`,
  `makeManual`, `setTriggerKind`, `setTimeDate`, `toggleWeekday`,
  `setScheduleInterval`, `setOneTimeDate`, `setEnabled`, `applyTrigger`, and a
  coordinator-idle guard; save/delete/clear/new/load-for-editing updated.
  `ContentView` gained the `triggerSection` card and a Library Auto toggle.
  `CreationPreparer` sets `willRunAutomatically` from the trigger.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 167 tests, 24 suites, pass
    (+1 preview test for schedule automatic-run reporting).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending. To verify: create a schedule whose next run is 1–2
  minutes out, enable it, leave the app running, and confirm the run fires (menu
  status + history) with the window closed; also confirm the next-three preview
  matches, disabling stops it, and relaunching re-registers an enabled schedule.
- Remaining defects / gaps:
  - The composer "Test now" and Library "Run" still execute via `WorkflowRunner`
    directly (with a coordinator busy-guard) rather than through admission; they
    are not queued/cancellable. Unify in 2.6.
  - The schedule calculator time zone is captured at launch; a time-zone change
    while running is not re-applied to existing registrations.
  - Card-set one-time dates remain card-only (text re-parse keeps only the time).
  - The registry wakes on the exact occurrence; there is no grace period or
    catch-up by design (missed runs skipped).
- With H1–H3 complete, plan 2.1 is functionally implemented pending the physical
  schedule verification above.

### Fix H3-d — One-time schedules did not fire (overshoot rejection)

- Status: done
- Defect (reported during the Test A schedule check): an enabled one-time
  schedule never ran and never appeared in history.
- Root cause: both the registry's fire-time re-validation and the coordinator's
  admission validation compared the one-time scheduled instant to the *current*
  time. `Task.sleep` wakes a few milliseconds after the scheduled instant, so at
  fire time the one-time date was strictly in the past and validation rejected it
  as "past due" — the event was silently dropped.
- Fix: admission (`RunCoordinator.submit`) now validates definitions
  structurally (no reference date); authoring/registration still enforce the
  past-due rule. The registry's fire-time re-validation uses the scheduled
  `fireDate` rather than the woken wall-clock time.
- Investigation evidence: the SwiftData store showed `Test 1` saved with
  `isEnabled = true` and a `oneTime` trigger ~40s in the future, but no run
  record. The running process was also an older binary than the latest build.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 185 tests, 26 suites, pass
    (was 183/26; +2). New coverage: a one-time schedule fires when the clock
    overshoots the scheduled instant, and the coordinator accepts an
    automatic one-time definition that has just fired.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending re-run of Test A on the rebuilt app (quit and relaunch
  so the fixed binary is running).

### Fix H3-e — Notifications suppressed while TaskOS is active

- Status: done
- Defect (reported after the schedule fired): a scheduled run reported
  `succeeded` in history but no notification was visible.
- Root cause: the app never assigned a `UNUserNotificationCenterDelegate`.
  When TaskOS is the active application, macOS suppresses a notification unless
  the delegate's `willPresent` opts into presenting it. `center.add` still
  succeeds, so history correctly showed success while nothing was shown.
- Fix: added `NotificationPresenter` (a `UNUserNotificationCenterDelegate` that
  returns `[.banner, .sound, .list]`) and activate it at app launch in
  `AppDelegate.applicationDidFinishLaunching`.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (relaunch and confirm the banner appears even when
  TaskOS is frontmost). Note: system Focus/Do Not Disturb or per-app
  notification settings can still suppress banners; success only means macOS
  accepted the request.

### Increment I1 — Copy Text (plan 2.2, partial; plan A10)

- Status: done
- Behavior delivered: a workflow can replace the clipboard with configured
  literal text, through text and cards. Typing `copy "meeting agenda"` (or
  `copy text "..."`) produces a Copy Text step with an editable text field and a
  note that it replaces clipboard contents; preview shows the text and that it
  replaces the clipboard; test writes to `NSPasteboard`. Copy text requires no
  permissions and the clipboard is only written, never read.
- Interfaces changed: added `ActionID.copyText` and `CopyTextAction` (with
  `maximumLength`); `ActionConfiguration.copyText`; registry descriptor;
  validation (non-empty, bounded length); `requiredPermissions`; parser
  `ParsedClauseKind.copyText` / `ParsedParameter.copyText` and a `copy`
  production; `CanonicalPhrase`; `ComposerActionDraft.copyText`,
  `updateCopyText`, unresolved handling; `SuggestionEngine` starter;
  `CreationPreparer` preview; app `CopyTextExecutor` registered in
  `AppComposition`; `ActionCard` UI and Add-action entry.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 175 tests, 25 suites, pass
    (was 167/24; +8). New coverage: quoted/keyword parsing, missing text needs
    input, canonical round-trip, composer definition, empty text blocks
    completion, validation bounds, and no required permissions.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (copy a workflow's literal text and paste to confirm;
  confirm the app never reads the clipboard).
- Remaining in plan 2.2: Hide Application (A2), normal Quit Application (A3) with
  protected-app rejection, specific-display selection for Arrange Window, and
  complete notification editing/permission handling review.
- Next eligible work package: 2.2 increment I2 — Hide and Quit Application with
  normal-quit safeguards.

### Increment I2 — Hide and Quit Application (plan 2.2, partial; plan A2 + A3)

- Status: done
- Behavior delivered: workflows can hide a running app and request a normal quit
  of a running app, through text and cards. Typing `hide Safari` or
  `quit Safari and Notes` produces the matching step with an application picker;
  `Hide an application` / `Quit an application` are available from Add action and
  as starters. Preview resolves the app, notes that Hide only works when running,
  and warns that Quit may wait on a dialog. The Quit executor never force-quits:
  it sends `terminate()`, waits up to 10s for the app to exit, then reports
  failure if a prompt is blocking. Hide/Quit reject (and skip at execution)
  TaskOS itself, Finder, and system infrastructure (Dock, loginwindow,
  SystemUIServer); both require no Accessibility permission.
- Interfaces changed: added `ActionID.hideApplication` / `.quitApplication`,
  `HideApplicationAction`, `QuitApplicationAction` (with
  `protectedBundleIdentifiers`), `ActionConfiguration` cases; registry
  descriptors; validation; `requiredPermissions`; parser
  `ParsedClauseKind.hideApplication`/`.quitApplication` and
  `hide`/`quit` productions (shared application-list collection refactored out of
  `parseOpen`); `CanonicalPhrase`; `ComposerActionDraft` cases with resolution and
  reconciliation; `SuggestionEngine` starters; `CreationPreparer` previews; app
  `HideApplicationExecutor` and `QuitApplicationExecutor` registered in
  `AppComposition`; `ActionCard` UI, Add-action entries, and preview titles.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 183 tests, 26 suites, pass
    (was 175/25; +8). New coverage: hide parse, quit list parse, missing app
    needs input, canonical round-trips, composer hide definition, protected quit
    rejection (Finder and TaskOS), hide validation, and no required permissions.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (hide a running app; quit an app with unsaved changes
  and confirm TaskOS reports the prompt instead of force-quitting; confirm a
  workflow cannot quit TaskOS/Finder).
- Remaining in plan 2.2: selectable specific display for Arrange Window (model
  exists; UI offers current/main), and a review of complete notification editing
  and permission handling. Lifecycle feedback-loop suppression belongs to 2.4.
- Next eligible work package: 2.2 increment I3 — specific-display selection and
  notification editing/permission review.
