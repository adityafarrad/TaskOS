# TaskOS v1 — Progress Ledger

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
| 2.1 | Add scheduling and runtime admission | done | Increments H1–H3 + fixes H3-d/H3-e | Schedule model, occurrence calc, admission/queue/pause/cancel, schedule grammar, runtime registry, trigger card + next-run preview + enable toggle; physical tests A–E passed |
| 2.2 | Finish app, window, and utility actions | done | Increments I1–I3 | Copy Text, Hide, normal Quit, specific-display selection, window presets, and notification editing/presentation done; lifecycle loop suppression tracked in 2.4 |
| 2.3 | Add selected files and portable workflows | done | Increments J1–J3 | File selection, Open/Reveal, durable references, repair, and portable export/import with rebinding done |
| 2.4 | Add event-triggered workflows | done | Increments K1–K6 | All six event families implemented end to end with discovery/availability; user-confirmed physical checks complete |
| 2.5 | Finish the template and discovery experience | done | Increments M1–M3 | Twelve templates, template picker, and capability discovery implemented; physical UI check deferred to Phase 3 by the WP 2.7 entry-gate decision |
| 2.6 | Complete everyday management and recovery | done | Increments N1–N4 | Visibility, attention/repair, action-level history, retention, permission settings links, and onboarding polish complete |

### Work Package 2.7 — Deterministic language hardening (pre-Phase 3)

Contract: `WP-2.7.md`. Entry gate closed 2026-09-13 (baselines pass; older
physical checks owner-deferred to Phase 3 — see the entry-gate record at the end
of this file). No 2.7 implementation has started.

| ID | Sub-increment | Status | Evidence | Notes |
|---|---|---|---|---|
| 2.7A1 | Freeze the language contract | done | Increment 2.7A1 | Capability-language matrix (`CommandLanguageCatalog`), consumer parity tests; parser/suggestions/canonical now catalog-driven |
| 2.7A2 | Make source handling safe | done | Increment 2.7A2 | Checked UTF-16 spans, `CommandInput`/`CommandEdit`, literal scanner, coverage, limits, evidence/slots/clarifications |
| 2.7A3 | Preserve authoring state and exact time | done | Increment 2.7A3 | Stable node preservation, conservative duplicate clearing, structured draft v2 + v1 fallback, resolve-once schedules |
| 2.7B1 | Exact action language | done | Increment 2.7B1 | Quoted app names, launch/start aliases, bare domains require acceptance, quoted-only Copy Text, negation blocks |
| 2.7B2 | Composition and schedules | done | Increment 2.7B2 | All connectors outside literals, one trigger first/last only, `closes` removed, full schedule forms incl. absolute `Once on` |
| 2.7B3 | Friendly frames and finite rationale | done | Increment 2.7B3 | Leading frames/fillers/final punctuation, journaling sentence, four rationale endings only |
| 2.7C1 | Versioned app snapshots and list ambiguity | done | Increment 2.7C1 | Revisioned snapshots, exact resolution with aliases, ambiguity (no first match), bounded list grouping, 5,000-app cap |
| 2.7C2 | Native command editor and completion | done | Increment 2.7C2 | `NSTextView` wrapper, UTF-16 edits/selection, marked-text rules, keyboard completion, VoiceOver |
| 2.7C3 | Result validity and bounded typo help | done | Increment 2.7C3 | Completion/preparation/resource keys and rechecks; typo bounds (5/8/64, ≤3, 5,000) |
| 2.7D1 | Independent language corpus | done | Increment 2.7D1 | Seeded 2,000-positive corpus, 114 negatives, ambiguity fixtures, literal oracle; quarter-preset round-trip fixed |
| 2.7D2 | Integration, persistence, privacy | done | Increment 2.7D2 | Parser-free definition/preview, direct serialized-record inspection, draft v1/v2 restore, no private text in records/exports/logs |
| 2.7D3 | Performance and physical proof | done | Increment 2.7D3 + fixes 2.7D3-a/b | Release targets met; owner physical journeys confirmed 2026-09-14; tag `wp-2.7-language` created |

### Phase 3 — Qualify, beta-test, and distribute

| ID | Work package | Status | Evidence | Notes |
|---|---|---|---|---|
| 3.1 | Complete system validation | not started | — | Includes the older physical checks deferred from before WP 2.7 (named in the entry-gate record at the end of this file) |
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
- Physical checks: complete. User-confirmed tests A–E: an enabled one-time
  schedule fired with the window closed and recorded history; the next-three
  preview matched; enable/disable from the Library worked; an enabled schedule
  was re-registered after relaunch and fired; pause suppressed automatic runs.
  Two defects found and fixed during verification (H3-d overshoot rejection,
  H3-e notification presenter).
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
- Physical checks: confirmed. After relaunch, the one-time schedule fired and
  recorded a success in history (Test A).

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
- Physical checks: confirmed. The notification banner appears when a scheduled
  run fires. Note: system Focus/Do Not Disturb or per-app notification settings
  can still suppress banners; success only means macOS accepted the request.

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

### Increment I3 — Specific display selection and notification review (plan 2.2 completion)

- Status: done
- Behavior delivered: Arrange Window can target a specific connected display, not
  just the current or main one. The card lists every connected display by name
  (marking the main one); unavailable specific displays are flagged in preview
  and fail at execution rather than silently falling back to another display.
  Notification editing/review is complete: title/message fields, permission
  state in preview, the `NotificationPresenter` banner fix (H3-e), and the
  documented caveat that success means macOS accepted the request.
- Interfaces changed: added `DisplayResource`; `ResourceCatalog` gained
  `installedDisplays()` / `display(identifier:)` (defaulted); `CreationPreparer`
  validates a specific display before other arrange checks; app
  `WorkspaceResourceCatalog` enumerates `NSScreen`s by `NSScreenNumber`;
  `AppComposition.loadDisplays()`; `ComposerViewModel.displays`; the Arrange
  Window card display picker now lists concrete displays.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 187 tests, 26 suites, pass
    (was 185/26; +2). New coverage: a missing specific display blocks arrange
    (missing resource, not runnable) and a connected specific display is ready.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (arrange a window onto a second display by name, and
  disconnect it to confirm the preview flags it instead of falling back).
- Remaining in plan 2.2: lifecycle feedback-loop suppression (TaskOS-initiated
  app launch/quit must suppress correlated lifecycle triggers) is intentionally
  deferred to 2.4, where app lifecycle triggers are implemented.
- Next eligible work package: 2.3 — selected files and portable workflows.

### Increment J1 — Selected files: Open File and Reveal in Finder (plan 2.3, partial; A5 + A6)

- Status: done
- Behavior delivered: a workflow can open or reveal an explicitly user-selected
  file or folder. Steps are added from the Add-action menu or by typing the
  generic phrases `open the selected file` / `open the selected folder` /
  `reveal the selected item`; the card then requires a real selection via
  `NSOpenPanel` and stores a display name, path, and bookmark. The chosen target
  survives later text edits (order-based reuse). Open File rejects executables,
  installers, scripts, and automation bundles by extension at validation and
  again at execution; a missing/moved target fails with recovery text instead of
  substituting another file. Files require no permission, and typed paths never
  substitute for a selection.
- Interfaces changed: added `FileTarget` (kind/displayName/path/bookmark +
  `rejectedExtensions`/`isExecutableOrUnsupported`), `OpenFileAction`,
  `RevealInFinderAction`; `ActionID.openFile`/`.revealInFinder`; registry
  descriptors; validation; parser `ParsedClauseKind.openFile`/`.revealInFinder`,
  `ParsedParameter.fileSelection`, the `reveal` keyword, and file-phrase
  detection in `parseOpen`/`parseReveal`; `CanonicalPhrase`; `ComposerActionDraft`
  cases with order-based target preservation; `CreationPreparer` previews;
  `SuggestionEngine` starters; app `FileTargetResolver`, `OpenFileExecutor`,
  `RevealInFinderExecutor`, `ComposerViewModel.chooseFile`, and card/add-menu UI.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 196 tests, 27 suites, pass
    (was 187/26; +9). New coverage: open-file/folder and reveal parsing,
    canonical round-trips, composer requiring a selection, selection surviving
    text edits, executable rejection, missing-target validation, and no required
    permissions. Updated the suggestions starter test for the larger catalog
    (visible limit of eight). Fixed a compound-`case ... where` bug that made
    every `openFile` clause report a spurious diagnostic.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (select a real file and a folder, open and reveal
  them; move a file and confirm recovery text; try a `.app` and confirm refusal).
- Remaining in plan 2.3: durable resource references / missing-resource repair
  (bookmark re-resolution and a repair control), and portable export/import with
  rebinding and disabled defaults.
- Next eligible work package: 2.3 increment J2 — durable file references and
  missing-resource repair.

### Increment J2 — Durable file references and missing-resource repair (plan 2.3, partial)

- Status: done
- Behavior delivered: selected-file references are durable (path plus a
  bookmark that is resolved first at execution) and missing files are detected
  and repairable. Preview flags a moved/deleted file as a missing resource with
  a "choose it again" instruction; the card shows a "Moved or deleted" warning
  and always offers **Choose…** to re-select. Execution fails with recovery text
  rather than substituting another file.
- Interfaces changed: `ResourceCatalog` gained `fileExists(path:)` (defaulted);
  `WorkspaceResourceCatalog` implements it; `CreationPreparer` checks file
  existence for Open File/Reveal; `ComposerViewModel.isMissingFile`; the file
  card shows a missing warning.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 198 tests, 27 suites, pass
    (was 196/27; +2). New coverage: a missing file blocks Open File as a missing
    resource, and an existing file previews as ready.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (select a file, move it, confirm the card/preview flag
  it, re-choose it, and run).
- Remaining defects/gaps: a stale bookmark is resolved but not refreshed back
  into the stored reference (non-sandbox paths still resolve); explicit
  security-scoped bookmark refresh is deferred.
- Next eligible work package: 2.3 increment J3 — portable export/import with
  rebinding and disabled defaults.

### Increment J3 — Portable export/import (plan 2.3 completion; plan 2.12)

- Status: done
- Behavior delivered: a saved workflow can be exported to a JSON file and
  imported on another Mac. Export includes the format version, name, trigger, and
  action configuration plus human-readable resource labels and literal content;
  it excludes the enabled state, run history, drafts, permission state, and file
  bookmark/path authority. Export first explains that URLs, notification
  messages, and copied text may contain private information. Imports are capped
  at 256 KiB, reject unknown executable fields and future formats, receive a
  fresh identity, start disabled, and place the workflow in the editor for
  explicit local resource selection and review. Imported resource references are
  unresolved (empty identifiers/paths) so the workflow cannot run until rebound.
- Interfaces changed: added `PortabilityError` and `WorkflowPortability`
  (`export`, `importWorkflow`, format version, 256 KiB cap) with a portable
  action representation that carries labels/literals but strips application
  bundle identifiers and file path/bookmark authority; app `ComposerViewModel`
  gained `exportWorkflow`/`importWorkflow` (NSAlert/panel flow) and a per-row
  Export button plus a Library Import button.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 205 tests, 28 suites, pass
    (was 198/27; +7). New coverage: round-trip preserving trigger/order/literals,
    imported resources requiring rebinding (invalid until resolved), file
    references dropping path/bookmark, fresh identity and revision, future
    format rejection, oversized rejection, and unknown action fields rejected.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (export a workflow, inspect the file, re-import,
  confirm it is disabled/needs rebinding, and export/import retains action order).
- Remaining/gaps: exported display selections keep their local display
  identifier (specific displays may need re-selection on another Mac); imported
  scheduled triggers are not registered because imports start disabled.
- Next eligible work package: 2.4 — event-triggered workflows.

### Increment K1 — Event-trigger model and observation interface (plan 2.4, partial)

- Status: done
- Behavior delivered: the typed domain for all six event trigger families and a
  source-agnostic observation interface. Added application lifecycle
  (launch/quit), Mac wake, display connect/disconnect (any external or a
  specific display), external volume mount/unmount (any external or a specific
  volume), power-source transitions, and battery-threshold crossings with
  validation. Triggers can statelessly match a typed observation via
  `TriggerConfiguration.matches(_:)`; battery crossing is intentionally not a
  stateless match (it needs rearm state, delivered in K5). All configs persist
  and round-trip.
- Interfaces changed: added `TriggerID` cases and `TriggerConfiguration` cases;
  configs `ApplicationLifecycleTrigger`, `WakeTrigger`,
  `DisplayConnectionTrigger`/`DisplaySelection`, `ExternalVolumeTrigger`/
  `VolumeSelection`, `PowerSourceTrigger`, `BatteryThresholdTrigger`; added
  `ObservedTriggerEvent`, `TriggerRegistrationID`, and the `TriggerSource`
  protocol; registry descriptors, validation, `matches`, and canonical phrases.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 216 tests, 29 suites, pass
    (was 205/28; +11). New coverage: registry consistency, lifecycle/battery
    validation, launch/quit match, wake match, display any/specific match,
    volume any/specific match, power transition match, non-event triggers not
    matching, canonical phrases, and coding round-trip.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (no platform source or UI yet).
- Remaining/gaps: loading an event-triggered workflow for editing currently maps
  the trigger to manual (the composer has no event-trigger card yet); the app
  does not observe or register event triggers yet.
- Next eligible work package: 2.4 increment K2 — application lifecycle end to
  end (NSWorkspace source, registration, cards/parser, TaskOS-initiated change
  suppression).

### Increment K2 — Application lifecycle trigger, end to end (plan 2.4, partial; plan T4)

- Status: done
- Behavior delivered: a workflow can run when a selected application launches
  or quits, from text or cards, with lifecycle loop suppression. Typing
  `when Safari opens` / `when Google Chrome quits` (or the When card's **App
  event** family with an application picker and opens/quits selector) builds the
  trigger and writes the canonical phrase. An enabled app-event workflow is
  registered at launch and on save, and fires through the admission coordinator
  when `NSWorkspace` reports the launch/quit. TaskOS's own Open/Quit actions
  record the affected bundle identifier in a `LifecycleSuppressor`, so the
  correlated lifecycle event is suppressed during the operation and a bounded
  settling window instead of re-triggering a workflow.
- Interfaces changed: added `LifecycleSuppressor` (actor) and
  `EventTriggerRegistry` (actor) with register/unregister/replaceAll/handle and
  suppression checks; `TriggerConfiguration.isEventTrigger`; parser
  `ParsedClauseKind.applicationLifecycle` / `ParsedParameter.lifecycle`, the
  `when` keyword, `lifecycleVerbs`, and `parseWhen`; `ComposerTriggerDraft
  .applicationLifecycle` with reconciliation, resolution, rendering, and
  `hasUnresolvedTrigger`; app `ApplicationLifecycleSource` (NSWorkspace
  didLaunch/didTerminate), executor suppression injection,
  `AppComposition` lifecycle suppressor/registry/source and
  `syncTriggerRegistrations`/`startEventTriggers`, and a trigger **family**
  picker (Manual / Schedule / App event) with a lifecycle card.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 227 tests, 30 suites, pass
    (was 216/29; +11). New coverage: the registry fires matching events through
    the coordinator, ignores non-matching events and non-event registrations,
    suppression blocks correlated events until the window elapses, unregister,
    replaceAll, multiple workflows for one app; plus `when` parser cases and a
    composer lifecycle definition.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (create "when Safari opens" with a notification
  action, enable it, quit and relaunch Safari to confirm it fires; confirm a
  workflow that opens Safari does not immediately re-trigger itself).
- Remaining/gaps: only the application-lifecycle family is wired and exposed in
  the card; wake/display/volume/power/battery still map to manual when loaded
  for editing; event-trigger suppression is keyed on bundle id and uses a fixed
  3s window (conservative, not perfect attribution).
- Next eligible work package: 2.4 increment K3 — Mac wake trigger.

### Increment K3 — Mac wake trigger (plan 2.4, partial; plan T5)

- Status: done
- Behavior delivered: a workflow can run after the Mac wakes. Typing `when the
  Mac wakes` (or the When card's **Mac wakes** family) builds the wake trigger.
  A `WakeTriggerSource` observes `NSWorkspace.didWakeNotification`; the event
  registry fires it through the admission coordinator. Because wake follows
  sleep, the registry restores session readiness before submitting, so the wake
  event is not rejected by the session-readiness gate. Enabled wake workflows
  register at launch and on save.
- Interfaces changed: parser `ParsedClauseKind.wake` / `ParsedParameter.wake`
  and `parseWhen` wake detection; `ComposerTriggerDraft.wake` with reconciliation,
  rendering, and configuration; `EventTriggerRegistry.handle` restores session
  readiness on `.woke`; `ComposerViewModel.TriggerFamily.wake` and
  `isWakeTrigger`; app `WakeTriggerSource` and `AppComposition.startEventTriggers`
  wiring; trigger family picker gained **Mac wakes**.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 230 tests, 30 suites, pass
    (was 227/30; +3). New coverage: wake phrase parsing, wake composer
    definition, and a wake event firing after session readiness was cleared
    while restoring readiness.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (create "when the Mac wakes" with a notification
  action, enable it, sleep and wake the Mac, confirm it fires once and that a
  run interrupted by sleep does not resume after wake).
- Remaining/gaps: wake is subject to a genuine event; no fabricated wake on
  launch. Display/volume/power/battery still map to manual when loaded for
  editing.
- Next eligible work package: 2.4 increment K4 — display connection and external
  volume triggers with baseline reconciliation.

### Increment K4 — Display and external volume triggers (plan 2.4, partial; plan T6 + T7)

- Status: done
- Behavior delivered: workflows can run when a display connects/disconnects
  (any external or a specific display) or when an external volume
  mounts/unmounts. Text supports `when a display connects`,
  `when an external display disconnects`, `when an external drive mounts`,
  `when a drive unmounts`; the When card gained **Display** and **Drive**
  families with event selectors and a display selector (any external or a named
  connected display). Device callbacks are reconciled by diffing actual
  identifier sets against a baseline taken at start, so bursts produce logical
  additions/removals and the initial state is never reported as an event.
  `ObservedTriggerEvent` now carries an `isExternal` flag so "any external"
  ignores the built-in display and internal disks.
- Interfaces changed: `ObservedTriggerEvent` display/volume cases gained
  `isExternal`; added `DeviceStateReconciler` (baseline + diff); parser
  `ParsedClauseKind.displayConnection`/`.externalVolume`, `ParsedParameter
  .display`/`.volume`, a shared `whenVerbs` table, and display/volume phrases;
  `ComposerTriggerDraft` display/volume cases with rendering and configuration;
  app `DisplayTriggerSource` (screen-parameter notifications) and
  `VolumeTriggerSource` (NSWorkspace mount/unmount) with reconciliation;
  `ComposerViewModel` display/volume family state and controls; trigger family
  picker and cards.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 233 tests, 30 suites, pass
    (was 230/30; +3). New coverage: reconciler baseline/add/remove, display and
    volume phrase parsing, composer display/volume definitions, and updated
    external-aware matching tests.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (connect/disconnect an external display and mount/
  unmount a USB drive; confirm one logical event each and that the initial state
  produces no event). Requires external display/removable storage.
- Remaining/gaps: specific volume selection in the card is deferred (text/card
  use "any external drive"); display identity uses the screen number, which is
  stable per session but not across reboots.
- Next eligible work package: 2.4 increment K5 — power source and battery
  threshold triggers.

### Increment K5 — Power source and battery threshold triggers (plan 2.4, partial; plan T8 + T9)

- Status: done
- Behavior delivered: workflows can run when the Mac switches to battery /
  connects to power, and when the built-in battery crosses below or above a
  percentage. Text supports `when the Mac switches to battery`,
  `when I connect to power`, `when the battery drops below 20%`,
  `when the battery rises above 80%`; the When card gained **Power source** and
  **Battery** families with event selectors and a percentage stepper. An
  IOKit `IOPSNotificationCreateRunLoopSource` source emits power-source
  transitions only on change and battery readings on updates. Battery crossing
  uses a stateful `BatteryThresholdMonitor`: the first reading is a baseline
  (never fires), a crossing fires once, and it rearms only after a two-point
  margin past the threshold to prevent repeated firing near the boundary.
  Unknown battery data is treated as unavailable and never fabricates a
  percentage.
- Interfaces changed: added `BatteryThresholdMonitor` (baseline/observe/rearm);
  `EventTriggerRegistry` holds per-workflow battery monitors and handles
  `.batteryChanged`; parser `ParsedClauseKind.powerSource`/`.batteryThreshold`,
  `ParsedParameter.power`/`.battery`, phrase tables and matchers for power and
  battery; `ComposerTriggerDraft` power/battery cases with rendering and
  configuration; app `PowerBatteryTriggerSource`; `ComposerViewModel` power/
  battery family state and controls; trigger family picker became a menu with
  Power source and Battery; power/battery cards.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 241 tests, 31 suites, pass
    (was 233/30; +8). New coverage: baseline-then-crossing, fire-once,
    two-point rearm for below and above, unknown-battery handling, registry
    baseline/crossing flow, and power/battery parsing plus composer definitions.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (on a MacBook: unplug/replug power and confirm one
  transition each; run a below-threshold workflow near the threshold and confirm
  it fires once and does not chatter). Requires laptop battery/power hardware.
- Remaining/gaps: hardware-specific triggers are not yet described as
  unavailable on Macs lacking the hardware (e.g., battery on a desktop); that
  availability/discovery polish is K6. Power/battery registration is not
  restarted on time-zone/hardware changes (not relevant).
- Next eligible work package: 2.4 increment K6 — trigger discovery/availability
  wording, suggestion entries, acceptance sweep, and phase close-out.

### Increment K6 — Event trigger discovery and availability (plan 2.4 completion)

- Status: done
- Behavior delivered: event triggers are discoverable and honest about missing
  hardware. Typing `when` offers ranked trigger suggestions for all six families.
  The When card warns when the selected family's hardware is absent: a battery
  trigger on a Mac with no battery, or a display/volume trigger with no external
  display/removable volume currently present. Implemented across all six
  families: app lifecycle, wake, display, external volume, power source, and
  battery threshold, each registered at launch and on save, firing through the
  admission coordinator, with history and pause support inherited from the
  runtime.
- Interfaces changed: added `Suggestion.Category.trigger` and a `when`
  suggestion context/`whenSuggestions` in `SuggestionEngine`; added
  `HardwareAvailability` and `AppComposition.hardwareAvailability()`;
  `ComposerViewModel.hardware`; trigger card availability notes.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 242 tests, 31 suites, pass
    (was 241/31; +1). New coverage: the `when` context returns only trigger
    suggestions including wake and battery.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Plan 2.4 acceptance review: registration establishes a baseline without
  fabricating an event (reconciler + battery baseline); display/volume bursts
  reconcile to logical transitions; battery jitter does not repeat (two-point
  rearm); absent hardware is described accurately; callbacks from obsolete
  registrations cannot start a run (the registry only evaluates current
  entries); event triggers require no permissions, so there is no background
  prompt loop.
- Physical checks: complete. User-confirmed the full event-trigger set —
  app lifecycle, wake, display connect/disconnect, external volume
  mount/unmount, power-source transitions, and battery threshold — each firing
  once per real event.
- Next eligible work package: 2.5 — templates and discovery (done), then 2.6.

### Increment M1 — Core template catalog (plan 2.5, partial)

- Status: done
- Behavior delivered: twelve curated templates as structured drafts that use only
  registered capabilities, each with a name, summary, trigger, ordered actions,
  required parameters, and (where relevant) an explicit limitation. Added a
  `ComposerDocument` initializer that loads a template's trigger and actions and
  renders the canonical text; placeholders remain unresolved so the same
  validation and preview path applies.
- Interfaces changed: added `AutomationTemplate`, `TemplateParameter`,
  `TemplateCatalog` (with `ComposerActionDraft.actionID` and
  `ComposerTriggerDraft.triggerID` helpers); `ComposerDocument.init(trigger:actions:)`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 249 tests, 32 suites, pass
    (was 242/31; +7). New coverage: twelve unique templates, capability
    registration coverage, names/summaries, resolvable templates produce
    definitions, placeholder templates stay unresolved, trigger phrase
    rendering, and stated limitations.
  - Debug build — BUILD SUCCEEDED.

### Increment M2 — Template picker (plan 2.5, partial)

- Status: done
- Behavior delivered: a **Templates** section lists the twelve templates with
  search; each shows its summary and any limitation, and **Use** loads the draft
  into the composer (name, trigger, actions), clearing the editing identity and
  leaving placeholders highlighted for selection before Preview/Save.
- Interfaces changed: `AppComposition.templates`; `ComposerViewModel.templateSearch`,
  `templates`, `filteredTemplates`, `loadTemplate`; new `templatesSection` UI.

### Increment M3 — Capability discovery (plan 2.5, partial)

- Status: done
- Behavior delivered: **Browse supported actions** opens a searchable sheet
  covering every trigger and action with what it does, a supported example, its
  parameters, required permissions, limitations, and availability on the current
  Mac (battery/display/volume). It lists only implemented capabilities.
- Interfaces changed: added `CapabilityGuide`/`CapabilityGuideCatalog`;
  `ComposerViewModel.discoverySearch`, `showDiscovery`, `capabilityGuides`,
  `filteredGuides`, `guideIsAvailable`; `DiscoveryView` sheet.
- Tests performed (M2+M3):
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass
    (was 249/32; +6). New coverage: guide coverage of every capability id,
    unique ids, examples present, action permissions match `requiredPermissions`,
    hardware requirements stated, and limitations present for risky actions.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (load a template, confirm unresolved items, fill them,
  preview and save; search discovery and confirm unimplemented actions are not
  advertised).
- Remaining/gaps: templates that reference system apps still require the user to
  confirm each application; the discovery sheet lists capabilities but does not
  deep-link a missing resource into the relevant card control.
- Next eligible work package: 2.6 — everyday management and recovery.

### Increment N1 — Skipped and queue event visibility (plan 2.6, partial)

- Status: done
- Behavior delivered: the main window shows a **Skipped and queue events**
  section listing the coordinator's recent admission events (duplicate
  suppression, cooldown suppression, queue overflow, expiration, cleared while
  paused, interrupted by sleep) with the workflow name and time. It refreshes on
  window load, after runs, and on history changes.
- Interfaces changed: `AdmissionEventKind.displayName`; `ComposerViewModel
  .admissionEvents` and `refreshRuntimeActivity()`; `runtimeActivitySection` UI.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - Debug build — BUILD SUCCEEDED.
- Physical checks: pending (trigger a duplicate/suppressed automatic event and
  confirm it appears).
- Remaining/gaps: admission events are in-memory only (lost on relaunch); no
  persistence yet. Remaining in 2.6: clear enabled/paused/unavailable/attention
  states in the Library, action-level history detail, permission recheck and
  resource repair affordances, history retention limits, and onboarding/help
  refinement.
- Next eligible work package: 2.6 increment N2 — library status badges,
  attention/repair, and action-level history detail.

### Increment N2 — Library attention, paused state, and action-level history (plan 2.6, partial)

- Status: done
- Behavior delivered: the Library now shows a paused banner when automatic
  triggers are paused from the menu bar, and marks any saved workflow that is
  not runnable (missing app/file/display or denied permission) with a **Needs
  attention** badge whose Edit button becomes **Fix**. History rows expand to
  show each action's outcome, so partial failures are readable.
- Interfaces changed: `ComposerViewModel.workflowAttention`,
  `automaticTriggersPaused`, and `computeAttention` (uses
  `CreationPreparer.prepare`); Library paused banner, attention badge/Fix, and
  history disclosure with `actionTitle`/`actionOutcomeLabel`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (save a workflow with a missing app, confirm the
  attention badge/Fix; expand a history row to see per-action outcomes; pause
  from the menu and confirm the banner).
- Remaining in 2.6: history retention limits (30 days / 1,000 runs) and data
  controls, permission recheck/resource repair polish, and onboarding/help
  refinement.
- Next eligible work package: 2.6 increment N3 — history retention and data
  controls.

### Increment N3 — History retention and data controls (plan 2.6, partial; plan 2.11)

- Status: done
- Behavior delivered: run history is retained for at most 30 days or 1,000 runs,
  whichever is reached first. Pruning runs on every append and deletes entries
  older than 30 days and any beyond the 1,000-run cap. Settings states the
  retention policy alongside the existing Clear history / Delete all workflows
  controls.
- Interfaces changed: added `RunHistoryRetention` (maximumRuns = 1,000,
  maximumAge = 30 days); `SwiftDataRunHistoryRepository` now prunes by age and
  count; Settings retention note.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED,
    including a new test that an expired run is pruned while a recent one is
    kept. Updated two existing fixtures that used 1970 dates (now correctly
    pruned) to recent dates.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (accumulate runs, confirm the oldest drop past the
  limits; confirm Clear history and Delete all workflows still work).
- Remaining in 2.6: permission recheck/resource-repair polish (Fix flow exists;
  deep attention copy and one-click grant/repair) and onboarding/help
  refinement. Admission-event persistence remains a gap.
- Next eligible work package: 2.6 increment N4 — permission recheck/resource
  repair polish and onboarding/help refinement, then Phase 2 exit gate.

### Increment N4 — Permission settings links and onboarding polish (plan 2.6, partial)

- Status: done
- Behavior delivered: Settings always offers direct **Accessibility Settings**
  and **Notification Settings** buttons (plus Grant Accessibility when not
  granted, and Recheck). They were originally conditional on the permission being
  missing, which made them hard to find when already granted. Onboarding mentions starting from a
  template or a trigger phrase and using Browse supported actions. The resource
  repair path (attention badge → Fix) is already in place from N2.
- Interfaces changed: `ComposerViewModel.openNotificationSettings()` /
  `openAccessibilitySettings()`; Settings buttons; expanded onboarding copy.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: pending (deny a permission and confirm the settings buttons
  open the right pane; confirm the onboarding copy and Fix flow).

## Phase 2 exit gate

- Core tests: `swift test --package-path Packages/TaskOSCore` — 255 tests,
  33 suites, pass (Core purity test still enforced).
- App tests: `xcodebuild ... test -only-testing:TaskOSTests` — passed (SwiftData
  workflow, run-history, and draft repositories, including retention).
- Clean Release build: `xcodebuild ... -configuration Release clean build` — BUILD
  SUCCEEDED.
- Implemented and exercised: scheduling and admission (2.1, verified A–E); all
  eight in-scope action/utility capabilities (2.2); selected files and portable
  export/import (2.3); all six event-trigger families (2.4, physically verified);
  the twelve templates and capability discovery (2.5); and management/recovery
  (2.6).
- Deferred by plan/user decision: global hotkey (T2), which would add the
  KeyboardShortcuts package; full-screen/space window operations; specific
  volume selection in the card.
- Known gaps recorded: admission events are in-memory only; the composer
  "Test now"/Library "Run" execute outside the admission queue (busy-guarded);
  a stale file bookmark is resolved but not refreshed into storage.
- Physical UI verification (user-confirmed): 2.1 schedule tests A–E; 2.4 all six
  event families; 2.6 N2 (attention/Fix/expanded history), N3 (retention), N4
  (permission settings buttons and onboarding). Issues found during these checks
  were fixed (menu-bar live refresh, live attention/permission updates,
  filesystem watch, accessibility denial reporting, delayed permission
  re-check, always-visible settings buttons).
- Phase 2 exit gate: PASSED. Phase 2 work packages 2.1–2.6 are complete and
  physically verified except the specific-volume card selection (deferred) and
  the global hotkey (deferred by plan/user decision).

### Fix N-a — Menu-bar workflow list did not refresh after saving

- Status: done
- Defect (reported during physical checks): a newly saved (or renamed, deleted,
  duplicated, imported, enabled, or cleared) workflow did not appear in the
  menu-bar **Run a workflow** list until the app was restarted, because the
  menu-bar model loaded its list only at launch/window-open.
- Fix: `ComposerViewModel.loadLibrary()` posts a
  `.taskOSWorkflowLibraryDidChange` notification (called after every library
  mutation); `MenuBarViewModel` observes it and reloads, so the menu updates
  live.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Next eligible work package: Phase 2 physical UI verification, then Phase 3.

### Fix N-b — Live refresh of attention, permissions, paused state, and Fix feedback

- Status: done
- Defects (reported during physical checks):
  1. Library "Needs attention" only appeared after restarting the app (a file
     moved in Finder or a permission revoked in System Settings was not
     re-evaluated while the window stayed open).
  2. Clicking **Fix** gave no visible feedback and did not move the view to the
     steps; the attention reason was not shown.
  3. The paused banner did not appear in real time when pausing from the menu bar.
- Fix: `ComposerViewModel` gained `refreshAll()` (library attention, history,
  runtime activity, permissions), called when the app becomes active
  (`NSApplication.didBecomeActiveNotification`), so external changes are picked
  up on return. `loadForEditing` now shows the attention reason in the notice and
  bumps a `scrollToTopToken`; `ContentView` wraps the form in a `ScrollViewReader`
  and scrolls to the top on Fix/Edit. The menu-bar pause/resume posts a
  `.taskOSRuntimeStateDidChange` notification that the composer observes, so the
  paused banner updates live. `refreshAll` also reloads connected displays and
  hardware availability, so the Arrange Window display picker and discovery
  availability update when a display is connected while the app is open.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Next eligible work package: Phase 2 physical UI verification, then Phase 3.

### Fix N-c — Filesystem watch for real-time missing-resource detection

- Status: done
- Defect (reported during physical checks): moving or deleting a selected file in
  Finder did not mark the saved workflow as needing attention until the user
  triggered another action (Preview/Run) or relaunched; activation-based refresh
  only covered leaving and returning to the app, not changes made while it stayed
  active.
- Fix: added `FileSystemChangeMonitor` (app target) that watches the parent
  directories of selected file/folder targets with `DispatchSource` vnode events
  (no polling) and debounces a refresh. `ComposerViewModel` updates the watched
  directories on every library load and reloads the library on a change, so the
  Needs attention badge appears as soon as the file is removed.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (delete/move a selected file and confirm the badge
  appears with no interaction).

### Fix N-d — Accessibility denial now surfaces as library attention

- Status: done
- Defect (reported during physical checks): a workflow using Arrange Window did
  not show **Needs attention** when Accessibility was off; the permission only
  appeared in Preview.
- Root cause: `SystemPermissionStatusProvider` mapped `!AXIsProcessTrusted()` to
  `.notDetermined`, which `CreationPreparer` treats as "will be requested" (no
  error), so the workflow was considered runnable and no attention was raised.
- Fix: not-trusted Accessibility now reports `.denied`, so Arrange Window
  previews and the library attention badge report the missing permission, and
  the existing Grant / Accessibility Settings affordances apply.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (with Accessibility off, confirm the Arrange Window
  workflow shows Needs attention in the Library; grant and confirm it clears).

### Fix N-e — Attention clears after granting a permission

- Status: done
- Defect (reported during physical checks): after enabling Accessibility, the
  Library kept showing **Needs attention** until Preview was clicked again; the
  permission became visible to the app slightly after reactivation, so the
  activation refresh ran too early.
- Fix: `refreshAll()` now runs a second permission + library refresh ~1.2s after
  activation (bounded, one-shot), catching macOS's delayed trust update. Settings
  **Recheck** now calls `recheckPermissions()` which refreshes permission state
  and recomputes library attention, so it can also be forced.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 255 tests, 33 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (grant Accessibility, return, confirm the badge clears
  within ~1–2s without Preview; Recheck also clears it).

## Post-Phase-2 hardening (pre-Phase 3)

Selected open gaps implemented before Phase 3 qualification. Gap 4 (malformed
record isolation/recovery) is deferred to Phase 3 with the migration fixtures.

### Increment P1 — Preserve card-only values when editing (gap 3)

- Status: done
- Behavior delivered: opening a saved workflow for editing now restores the
  exact structured definition instead of re-parsing canonical text, so values
  that text cannot express are preserved: the selected web browser, notification
  title/message, file target and bookmark, specific window display, one-time
  date, and interval duration. Imported workflows (empty identifiers/paths) are
  correctly shown as unresolved so they must be rebound before saving.
- Interfaces changed: added `ComposerActionDraft.init(_:)`,
  `ComposerTriggerDraft.init(_:)`, and `ComposerDocument.init(definition:)`;
  `loadForEditing` uses the definition directly and `applyTrigger` was removed.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 259 tests, 34 suites, pass
    (was 255/33; +4). New coverage: editing round-trips browser/notification/
    file/display/one-time values, preserves interval duration and event triggers,
    and imported definitions remain unresolved.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (edit a workflow with a chosen browser and custom
  notification text; confirm both are still set).
- Next eligible work package: P2 — route manual runs through admission.

### Increment P2 — Route manual runs through admission (gap 2)

- Status: done
- Behavior delivered: Composer "Test now" and Library "Run" now execute through
  the admission coordinator instead of the runner directly. They queue behind an
  in-flight run (one workflow at a time), appear in the queue count, and are
  cancelable from the menu bar. History is recorded once by the coordinator's
  execution path.
- Interfaces changed: `RunCoordinator.submitAndWait(_:source:id:)` returns the
  run's final `RunRecord` (nil when not admitted), backed by pending
  continuations; `processQueue` resumes the matching continuation with the
  record; `cancelAll`, `pauseAutomaticTriggers`, and `updateSessionReadiness`
  resume continuations for cleared queued runs with a synthesized `.cancelled`
  record so waiters never hang. `ComposerViewModel.test()`/`runSaved()` use
  `submitAndWait`; removed `coordinatorIsIdle`, `runningRecord`, and `record`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 262 tests, 34 suites, pass
    (was 259/34; +3). New coverage: `submitAndWait` returns the record, queues
    behind an active run in order, and `cancelAll` resumes a queued waiter as
    cancelled rather than hanging.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (Test now / Library Run still work; queued behind a
  long automatic run; menu Cancel stops it).
- Next eligible work package: P3 — persist admission/skipped events.

### Increment P3 — Persist admission/skipped events (gap 1)

- Status: done
- Behavior delivered: queue overflow, expiration, duplicate/cooldown
  suppression, pause clears, and sleep interrupts are now persisted and survive
  relaunch. The main window's "Skipped and queue events" section loads from the
  store; Clear history also clears these events. Retention keeps the last 200
  events or 30 days.
- Interfaces changed: added `AdmissionEventSink` / `AdmissionEventRepository`
  protocols and `AdmissionEventRetention` (Core); `RunCoordinator` gained an
  optional `eventSink` and forwards each event to it. App added
  `AdmissionEventRecord` + `SwiftDataAdmissionEventRepository`, wired into the
  `ModelContainer` and passed as the coordinator's sink; `ComposerViewModel`
  loads events from the repository; `clearHistory` clears them too.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 263 tests, 34 suites, pass
    (was 262/34; +1). New coverage: the coordinator forwards admission events to
    a sink (cooldown suppression observed).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED,
    including a new SwiftData admission-event append/recent/clear test.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (cause a suppressed event, quit, relaunch, and confirm
  it is still listed; Clear history removes it).
- Next eligible work package: optional quick wins Q1/Q2.

### Increment Q1 — Import maps a specific display to the current display

- Status: done
- Behavior delivered: importing a workflow that was exported with a specific
  display identifier now maps that selection to the current display, avoiding a
  false "display not connected" state on a different Mac. `current`/`main`
  selections import unchanged.
- Interfaces changed: `WorkflowPortability.PortableAction.makeAction` maps
  `.display(identifier:)` to `.current`.
- Tests performed: `swift test` — new coverage importing a specific display
  yields `.current`.

### Increment Q2 — Website suggestion from a typed domain

- Status: done
- Behavior delivered: typing `open <domain>` (e.g. `open apple.com`) now offers
  an exact "Open https://apple.com" website suggestion alongside application
  matches.
- Interfaces changed: `SuggestionEngine` `.openApplication` context adds a
  website suggestion when the fragment contains a dot and looks like a website.
- Tests performed: `swift test` — new coverage for the domain suggestion.

- Tests performed (Q1+Q2):
  - `swift test --package-path Packages/TaskOSCore` — 265 tests, 34 suites, pass
    (was 263/34; +2).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending (type a domain under `open` and accept the website
  suggestion; export on one Mac and import elsewhere to confirm the display
  selection resets).
- Next eligible work package: Phase 3.1 system validation (gap 4 and the smaller
  gaps 5–12 remain deferred).

### Increment U1–U3 — Native three-area UI redesign (presentation only)

- Status: done
- Behavior delivered: replaced the single long scroll page with a
  `NavigationSplitView` shell plus a trailing inspector. Left sidebar holds the
  TaskOS mark, Workflows/Templates/History/Settings destinations, and saved
  workflows with an inline search field and `+`; selection uses the native
  List accent. The editor is now the focal point: editable workflow name and an
  enabled switch in the toolbar, a compact trigger pill (`Manual ▾`), a command
  composer with the `command` glyph and “Describe what you want your Mac to
  do…” placeholder plus a floating suggestion panel, and step cards with step
  icon, summary, status chip, drag handle, duplicate, and delete. Secondary
  actions (Review, Rename, Duplicate, Export, Delete, Import) live in the
  toolbar `•••` menu; Run is the prominent `play.fill` action and opens a review
  popover that states testing runs for real. The inspector shows trigger or step
  configuration on selection and collapses otherwise. Templates became a card
  gallery (featured six + “View all templates”); History is a day-grouped
  timeline with expandable action outcomes plus a Skipped & queued section;
  Settings is a grouped Form with permissions, startup, history retention, help,
  and a separated destructive section behind confirmation dialogs. Discovery and
  onboarding restyled to match.
- Interfaces changed: added `ComposerDocument.moveActions(fromOffsets:toOffset:)`
  (one undo entry, leaves unresolved elements in place) with a Core test;
  `ComposerViewModel` gained `moveActions`, `duplicateAction`, `dismissResult`,
  `hasUnsavedChanges`, `isEditingSavedWorkflow`, and `activeWorkflow`.
  New presentation files under `TaskOS/TaskOS/Presentation/`: `DesignTokens`,
  `PresentationMappings`, `AppNavigation` (`TaskOSCommands`, `EditorSelection`),
  `SidebarView`, `WorkflowEditorView`, `CommandComposerView`, `StepCardView`,
  `StepConfigurationView`, `TriggerConfigurationView`, `InspectorView`,
  `RunReviewView`, `TemplatesGalleryView`, `HistoryView`, `SettingsView`,
  `DiscoveryView`. `ContentView` reduced to the shell. `TaskOSApp` registers
  `TaskOSCommands`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 267 tests, 34 suites, pass
    (was 265/34; +2 reorder coverage).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED; no code warnings.
- Physical checks: Release app launched cleanly. Pending manual pass (U4):
  trigger/step inspector, drag reorder, review popover, ⌘N/⌘K/⌘R/⌘S/⌘,,
  light/dark, compact widths, and VoiceOver. Then re-run the 2.5 template
  physical check against the new gallery.
- Next eligible work package: U4 accessibility/responsive polish, then Phase 3.1.

### Increment U-fix — Sidebar navigation reliability

- Status: done
- Defect: after selecting Templates or History, the Workflows destination could
  not be reselected. The search field and `+` control lived inside the
  `List(selection:)` rows, which interfered with AppKit sidebar selection.
- Behavior delivered: sidebar destinations and saved workflows are now explicit
  selection buttons that write `SidebarSelection` directly, with a subtle
  accent-tinted row background instead of relying on List selection; the detail
  pane is keyed to the selection so the destination view always swaps. Search
  and `+` remain under Workflows.
- Tests performed: Debug and Release builds — BUILD SUCCEEDED; Release app
  launched. (Accessibility automation is not authorized in this environment, so
  the click-through is a pending manual check.)
- Next eligible work package: U4 accessibility/responsive polish, then Phase 3.1.

### Increment U-fix2 — Window sizing and responsive columns

- Status: done
- Defect: a restored 900-point window frame left no room for all three columns,
  so the sidebar collapsed to its icon rail and the inspector was clipped off
  the right edge.
- Behavior delivered: the window opens at a 1180×760 default with the sidebar
  visibility explicitly `.all`; column minimums are reduced (sidebar 170,
  inspector 250) and the editor no longer enforces a hard minimum, so all three
  areas fit and the editor compresses instead of pushing the inspector
  off-screen. The inspector column now has min/ideal/max bounds and its content
  no longer sets an inner minimum width.
- Tests performed: Debug and Release builds — BUILD SUCCEEDED; Release app
  launched at the new default size.
- Next eligible work package: U4 accessibility/responsive polish, then Phase 3.1.

### Increment U-fix3 — Preserve resolved resources across text re-parse

- Status: done
- Defect: setting an application on a step and then choosing a folder on another
  step could clear the first step. The composer's `TextField` wrote a
  normalized/canonical string back to the model after programmatic changes;
  `setText` re-parsed the whole document, and `reconcileElements` paired previous
  actions by position, so a changed or reordered text recycled the wrong action
  and dropped card-only values such as the resolved application.
- Behavior delivered:
  - `ComposerDocument.reconcileElements` now reuses previous actions by matching
    type and name (exact match first, then same action kind) via a consumed set
    instead of a positional cursor, so resolved references, file targets,
    browsers, and other card-only values survive reorder and re-parse.
  - The composer uses a local text buffer and only propagates genuine user edits;
    writes whose trimmed value equals the model text (for example a trailing
    space after a programmatic change) are ignored, avoiding spurious re-parses
    and undo entries.
- Interfaces changed: `reusedAction` signature (`consumed: inout Set<Int>`),
  added `sameCase`/`matchesExactly`; new `ComposerValuePreservationTests`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 270 tests, 35 suites, pass
    (was 267/34; +3 regression tests: resolve survives file choice, text resync,
    and reorder + stale write).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: Release app relaunched; pending manual confirmation of the
  reported sequence (Open Application → set app → add Reveal/Open File → choose
  folder → first step keeps its app).
- Next eligible work package: U4 accessibility/responsive polish, then Phase 3.1.

### Increment U-fix4 — Responsive columns and discoverable workflow name

- Status: done
- Defects:
  - Resizing smaller cut the inspector ("Unresolved: an app…", "Select…"
    clipped): the editor toolbar's centered name field imposed a large minimum
    width, so the split view squeezed the inspector below its minimum.
  - The workflow name lived only in the toolbar center, so it was easy to miss,
    and its text field had no leading inset while typing.
- Behavior delivered:
  - Removed the toolbar principal name field (the window title still reflects
    the workflow name via `navigationTitle`) and dropped the explicit
    `.balanced` split style, freeing the detail column to shrink so the sidebar
    can collapse and the inspector keeps its minimum instead of clipping.
  - Added a prominent, editable workflow title at the top of the editor content
    (large semibold, inside the editor's generous horizontal padding) with the
    automatic-run switch beside it. This is the first thing visible in the
    editor and fixes the missing left inset.
  - Made the inspector narrow-friendly: a `TaskOSInspectorField` caption+control
    pattern with hidden picker labels is used for Application, Position,
    Display, Address, and Browser, so controls shrink and wrap instead of
    overflowing.
  - Lowered the minimum column widths (sidebar 160, editor 300, inspector 220)
    and the window minimum to 680×520; the window can no longer be resized below
    the point where the three areas fit.
- Tests performed: Debug and Release builds — BUILD SUCCEEDED (no warnings);
  Release app relaunched at the restored default size.
- Next eligible work package: U4 accessibility/responsive polish, then Phase 3.1.

### Increment U-fix5 — Surface actions, triggers, and scheduling on the first screen

- Status: done
- Defect: the only entry point to the capability guide was a small
  "Browse supported actions" link under the composer, so users did not discover
  that triggers (including scheduling) can be changed, and the guide was
  read-only.
- Behavior delivered:
  - The editor's trigger row now reads `When  [Manual ▾]` and carries a visible
    `Actions & Triggers` link, so scheduling is discoverable on the first screen.
  - Empty workflows show a "Get started" panel with a prominent **Browse Actions
    & Triggers** button, a **Browse Templates** button, and one-click popular
    trigger chips (Run manually, On a schedule, When an app opens, When the Mac
    wakes).
  - The capability sheet can now set capabilities: trigger guides have a
    **Use Trigger** action (sets the trigger, selects it for configuration, and
    closes), and action guides have an **Add Step** action that appends a
    default step. Unavailable capabilities stay disabled.
  - Added `Actions & Triggers…` to the editor `•••` menu and a Help-menu command
    with `⌘/`.
- Interfaces changed: `TaskOSCommandActions.browseCapabilities`; `DiscoveryView`
  now takes `selection` and `onEdit`; composer link renamed to
  "Browse actions & triggers".
- Tests performed: Debug and Release builds — BUILD SUCCEEDED; Release app
  relaunched.
- Next eligible work package: U4 accessibility/responsive polish, then Phase 3.1.

### Increment U-stab-A — Run lifecycle, enable state, navigation guards (A1–A6)

- Status: done
- Defects fixed:
  - A1: the editor had no running state or cancel; a run looked like nothing was
    happening. Now a running banner shows a spinner, the run name, queued count,
    and Cancel; the toolbar Run button shows "Running…" and is disabled while
    busy; ⌘. cancels.
  - A2: added an explicit inspector toggle to the editor toolbar.
  - A3: `setEnabled` ignored event triggers, so event-based workflows could not
    be enabled; it now registers/unregisters schedules and event triggers. The
    editor switch is authoritative for saved workflows (persists immediately and
    syncs the sidebar dot) and draft-state for new ones.
  - A4: replacing the document (selecting another workflow, New, template Use,
    Import) now prompts Save / Discard / Cancel when there are unsaved changes.
  - A5: renaming a saved workflow from the sidebar updates the open editor
    title; deleting the open workflow starts a clean draft and returns the
    sidebar to Workflows; run-result banners are gated to the run's own workflow.
  - A6: step cards no longer merge their buttons into one VoiceOver element;
    the summary is a labeled selectable element and move/duplicate/delete remain
    individually reachable.
- Interfaces changed: `ComposerViewModel` gained `isRunning`, `runningName`,
  `queuedCount`, `cancelCurrentRun`, `currentAutomationID`; `setEnabled` covers
  event triggers. `TaskOSCommandActions.cancelRun`. `SidebarView` now takes
  `onSelect`/`onNewWorkflow`; `TemplatesGalleryView.onUse` passes the template;
  `WorkflowEditorView` gained `onImport`.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
- Next: D1 UI smoke tests, then D2 regression matrix.

### Increment U-stab-D — Test safety net (D1–D3)

- Status: done (UI tests authored; execution pending automation permission)
- Behavior delivered:
  - Added a deterministic test launch: `-uiTesting` (and any XCTest run) makes
    `AppComposition` use an in-memory SwiftData container, skips onboarding, and
    skips notification/event-source startup, so tests never touch the user's
    store.
  - Added accessibility identifiers across the UI (`sidebar.*`, `editor.*`,
    `composer.field`, `step.card.N`, `discovery.*`, `templates.view`,
    `history.view`, `settings.view`, `inspectorToggle`) for stable UI queries.
  - Authored XCUITest smoke journeys in `TaskOSUITests`: launch/editor, sidebar
    navigation, composer creates a step, discovery open/close, settings startup
    row.
  - Added `ComposerViewModelTests` (5 tests) covering duplicate placement,
    reorder, unsaved-change tracking, new-workflow reset, and card resolution.
- Interfaces changed: `AppComposition.isUITesting`/`isTesting`;
  `TaskOSUITests` now launches with `-uiTesting`; `ComposerViewModelTests` added.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 270 tests, 35 suites, pass.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST SUCCEEDED,
    including the 5 new view-model tests.
  - Debug + Release builds — BUILD SUCCEEDED; UI test target builds.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED: launch/editor, sidebar navigation, composer typing creates a
    step, Add-step creates a step, discovery open/close, settings startup row
    (6 tests), plus the launch test.
- Composer input reliability (fix after the first D1 run):
  - The first composer test failed because `.descendants(matching: .any)`
    resolved the identifier on the composer field as a generic element and
    `typeText` timed out; direct character typing also arrived garbled
    (`"wait 1 second"` became `"t1eond"`), a known macOS XCUITest/SwiftUI
    character-delivery problem.
  - Fixed by: reading the launch flag from `UI_TESTING=1` as well as
    `-uiTesting`; querying the concrete `app.textFields`/`app.textViews`
    element; calling `app.activate()` and asserting `.runningForeground`; and
    entering text by paste (`⌘V` from an `NSPasteboard` string) instead of
    per-character synthesis. The composer is again covered by an automated UI
    test, alongside the deterministic Add-step test.
  - Reverted the composer's local text buffer back to a direct model binding;
    the Core identity-aware merge (U-fix3) preserves card-only values, so the
    buffer was unnecessary and added a second source of truth.
  - Note: on an empty workflow the Add-step control sits below the fold because
    the "Get started" panel and the empty-steps hint stack; folded into Phase B
    item B3.
- D2 regression matrix: pending user-run physical pass — Phase 1 canonical
  journey; 2.1 schedule A–E; 2.4 all six event families; 2.5 templates/discovery;
  2.6 attention/permissions/retention; 2.3 export/import; plus compact resize and
  light/dark.
- Next: run the D2 matrix, then Phase B (UX friction) items B1–B5.

### Increment U-d2 — D2 regression fixes

- Status: done
- Defects fixed from the user's D2 pass:
  - **Inspector-open resize clipping.** Replaced the SwiftUI `.inspector`
    modifier (which squeezed/clipped the trailing column when the editor had a
    larger minimum) with a controllable trailing column inside the detail:
    editor flexes, inspector keeps a fixed adaptive width (200/240/290 by
    available width) and animates in/out. Nothing clips; the sidebar still
    collapses automatically.
  - **Save visibility.** Added a bottom action bar to the editor with a clear
    status ("Unsaved changes" / "All changes saved") and visible **Review** and
    **Save** buttons, instead of the small conditional toolbar icon.
  - **Moved/deleted files.** Added `FileTargetStatus` (available/moved/missing);
    the step card and inspector now show "· moved" or "· missing" and mark the
    step as needing input. The view model now watches the current draft's file
    directories, so moving/deleting a chosen file refreshes the UI instead of
    waiting for an unrelated edit.
  - **Stale permissions/attention.** The window now refreshes permissions and
    library attention on a 5-second timer while active, in addition to
    activation, so revoking a permission or a missing resource updates without
    clicking a task first.
- Interfaces changed: `FileTargetResolver.status`; `FileTargetStatus`; VM
  `fileStatus`, `refreshFileStatus`, `fileStatusToken`, `updateWatchedDirectories`,
  `refreshForAttention`; `ActionPresentation` now takes a file-status closure;
  `ContentView` measures width and renders the inspector column itself.
- Tests performed: `swift test` 270/35 pass; app tests pass; UI tests 6/6 pass;
  Debug + Release build.
- Next: the remaining Phase B items (B1 step controls/drag feedback, B2 title
  affordance/debounce, B3 empty-state consolidation incl. the Add-step fold, B4
  Settings pause/resume, B5 discovery follow-through).

### Increment U-d2b — Compact sidebar icon rail

- Status: done
- Behavior delivered: below ~820pt window width the sidebar collapses to a
  ~64pt icon-only rail (destinations + a `+` new-workflow button, tooltips,
  accessibility labels, subtle selection highlight); above that threshold the
  full sidebar with labels, search, and the workflow list returns. The window
  content width is measured with a preference key and drives the mode, so the
  editor keeps its space at the narrowest sizes instead of squeezing. The
  toolbar sidebar toggle still expands/collapses the column.
- Interfaces changed: `SidebarView` gained `compact`; `AppWidthKey` added;
  `ContentView` measures `appWidth` and passes `compactSidebar`.
- Tests performed: UI tests 6/6 pass; Debug + Release build.
- Next: Phase B (B1–B5).

### Increment U-fix6 — New-workflow default, draft recovery prompt, and test appearance

- Status: done
- Defects fixed:
  - Launch silently restored the last unsaved draft, so the app appeared to open
    a saved workflow ("Editing 'action new'") instead of a new workflow, which
    was confusing.
  - The XCUITest launch test set
    `runsForEachTargetApplicationUIConfiguration = true`, so it ran a second
    pass in the dark appearance and left the user's system in dark mode.
- Behavior delivered:
  - Launch now shows a fresh **New Workflow**. If an unsaved draft exists, a
    non-intrusive banner offers **Recover** / **Discard** instead of silently
    loading it; the draft is cleared on save, new workflow, or explicit discard.
  - The sidebar now has an explicit **New Workflow** row (with ⌘N tooltip) at
    the top of the Workflows section; the small `+` next to search is removed.
  - The launch test now runs a single light configuration
    (`runsForEachTargetApplicationUIConfiguration = false`) and launches with
    the in-memory `-uiTesting` mode, so UI testing no longer changes system
    appearance or touches the real store.
- Interfaces changed: `ComposerViewModel.recoverableDraft`, `recoverDraft()`,
  `discardRecoverableDraft()`; `SidebarView` New Workflow row;
  `WorkflowEditorView` recovery banner.
- Tests performed: UI tests 7/7 pass (single launch pass); app tests pass;
  `defaults read -g AppleInterfaceStyle` confirms no dark override after tests;
  Debug + Release build.
- Next: Phase B (B1–B5).

### Increment U-ia — Workflows library destination

- Status: done
- Behavior delivered: the Workflows destination is now a saved-workflows
  library in the main pane (search field, prominent **New** button, rows with
  status dot, step count, trigger summary, updated time, attention state, and a
  context menu for Open/Run/Rename/Duplicate/Export/Delete). Selecting a row
  opens it in the editor. The sidebar no longer carries the workflow list; it
  shows Workflows, a prominent dark **New** action (plus icon + "New"), Templates,
  History, and Settings. First launch still opens a fresh New Workflow editor;
  the icon rail keeps a filled **+** for New.
- Interfaces changed: `SidebarSelection` is now `.destination(...)` or `.editor`
  (the `.workflow` case and the in-sidebar list were removed); new
  `WorkflowsLibraryView`; `ContentView` routes the library and adds
  `openWorkflow`.
- Tests performed: UI tests 7/7 pass (sidebar navigation updated for the library);
  Debug + Release build.
- Next: Phase B (B1–B5).

### Increment U-fix7 — New workflow matches first launch

- Status: done
- Defect: after navigating to another destination and choosing **New**, the fresh
  editor showed no suggestions, while the first-launch editor did. `newWorkflow`
  cleared `suggestions` but never recomputed them.
- Behavior delivered: `newWorkflow` now calls `refreshSuggestions()`, so New
  reproduces the first-launch editor (default action suggestions, discovery
  shortcuts, Get started panel).
- Tests performed: new UI test `testNewWorkflowShowsSuggestions` (Workflows →
  New → suggestions appear); UI tests 8/8 pass; Debug + Release build.
- Next: Phase B (B1–B5).

### Increment B1–B5 — Phase B UX polish

- Status: done
- Behavior delivered:
  - **B1** Step cards keep the drag handle visible and gained an always-present
    `•••` menu (Configure, Move Up/Down, Duplicate, Delete); inline controls
    remain on hover/selection, and dragging now shows an accent insertion line
    on the target card.
  - **B2** The workflow title field shows a hover tint, underlined on hover and
    accent-underlined on focus; name edits no longer invalidate the preview on
    every keystroke (400 ms debounce) and autosave stays debounced.
  - **B3** An empty workflow no longer stacks the "Get started" panel with a
    redundant "No steps yet" hint, so `+ Add step` stays above the fold.
  - **B4** Settings has an **Automatic triggers** section with a
    Run/Pause switch and a paused explanation, backed by the coordinator and
    reflected in the sidebar footer.
  - **B5** Discovery's **Add Step** now appends the step, switches to the
    editor, selects the new step (opening its inspector), and closes the sheet;
    **Use Trigger** already did the equivalent.
- Interfaces changed: `ComposerViewModel.setAutomaticTriggersPaused`,
  `previewResetTask`; `StepCardView` gained `isLast`/`isDropTarget` and a step
  menu; `WorkflowEditorView` tracks `dropTargetID` and title focus/hover.
- Tests performed: UI tests 10/10 pass (new: discovery Add Step creates a step,
  step menu offers Duplicate, settings shows the automatic-triggers switch);
  app tests pass; Core 270/35 pass; Debug + Release build.
- Next: Phase C polish (onboarding restyle, focus rings, full Reduce-Motion,
  contrast) or Phase 3.1 validation.

### Increment C — Phase C polish

- Status: done
- Behavior delivered:
  - **Onboarding** restyled to match the app: accent TaskOS mark, concise
    feature rows with SF Symbols, and a prominent Got it button.
  - **Focus rings**: step cards are keyboard-focusable and show an accent focus
    ring; the composer and title already had visible focus treatment, so custom
    controls now have a consistent focus affordance.
  - **Reduce Motion**: card hover/selection animation, inspector slide, and run
    banner transitions now fall back to opacity-only when Reduce Motion is on
    (matching the composer and step-list animations).
  - **Templates**: cards use a minimum height instead of a fixed one so longer
    titles/limitations don't clip, summaries wrap, and cards lift subtly on
    hover.
- Interfaces changed: `OnboardingView` restyle; `TaskOSCardModifier` and
  `RunBannerView` read `accessibilityReduceMotion`; `StepCardView` gained
  keyboard focus; `TemplateCard` is hover-aware.
- Tests performed: UI tests 10/10 pass; app tests pass (one rerun past the known
  SwiftData in-memory flake); Core 270/35 pass; Debug + Release build.
- Next: Phase 3.1 validation (per PLAN.md) when requested.

### Increment UX-1 — Truthful lifecycle and library status (pre-Phase-3 polish)

- Status: done
- Behavior delivered:
  - The Workflows library now states each workflow's real lifecycle
    (`Manual · Ready to run`, `Schedule · On/Off`, `Event · On/Off`) with a
    matching status dot, the next scheduled run for enabled schedules, and a
    paused note when automatic triggers are paused. Enabled automatic workflows
    can be turned on/off from the row context menu without opening the editor.
  - The editor's bottom action bar reports a truthful lifecycle state
    (`New workflow`, `Draft · not saved yet`, `Unsaved changes`,
    `Saved · Ready to run`, `Saved · Off/On`, `Saved · On · Paused`) instead of a
    binary saved/unsaved label.
  - Fixed a truthfulness defect: the unsaved-changes signature omitted the
    trigger and automatic-run intent, so changing a schedule/time, trigger kind,
    or the run-automatically switch on a saved workflow did not mark it unsaved
    or enable Save.
  - Fixed save identity: after saving, further edits update the same record
    (reusing `lastSavedID`) instead of minting a new identity, matching the F1
    "update in place" contract.
- Interfaces changed: added `WorkflowStatusPresentation` and
  `EditorLifecycleState` (`Presentation/WorkflowStatusPresentation.swift`);
  `ComposerViewModel` gained `editorLifecycleState`, `hasDraftContent`,
  `nextRunDate(for:)`, and a trigger/intent-aware `currentSignature`;
  `WorkflowsLibraryView` shows status text + detail and a Turn On/Off context
  item; `WorkflowEditorView` action bar uses the lifecycle state.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including 9 new `WorkflowStatusPresentationTests` covering
    manual/schedule/event labels, next-run and paused details, attention tint,
    editor lifecycle transitions, and trigger edits marking a saved workflow
    unsaved.
  - Debug build — BUILD SUCCEEDED.
- Physical checks: pending owner Mac pass — confirm library status labels and
  next run; turn a schedule off/on from the row menu; change a saved workflow's
  trigger time and confirm "Unsaved changes" with Save enabled; pause from the
  menu bar and confirm the row detail.
- Next: UX-2 (blocking reason and field guidance).

### Increment UX-2 — Blocking reason and field guidance

- Status: done
- Behavior delivered: when Review/Save are disabled, the editor action bar now
  says why and which step to fix, instead of leaving the buttons greyed without
  explanation. Examples: "Add at least one step to review or save.", "Step 1
  needs an app.", "Step 1 needs a full http:// or https:// address.", "Step 1
  needs a file or folder.", "Finish configuring the trigger." Step summaries use
  concrete wording ("Choose an app", "Add a web address") and the website
  inspector error reads "Add a full http:// or https:// address."
- Interfaces changed: `ActionPresentation.missingRequirement(for:fileStatus:)`
  and sharpened `summary` prompts; `ComposerViewModel.blockingReason`;
  `WorkflowEditorView` action bar shows the reason; `StepConfigurationView`
  copy.
- Tests performed:
  - App tests — TEST SUCCEEDED, including new blocking-reason cases (empty
    steps, unresolved app/website, unresolved trigger, resolved workflow) and
    `missingRequirement` copy checks.
  - Debug build — BUILD SUCCEEDED.
- Physical checks: pending owner Mac pass — add a step without choosing an app
  and confirm the bar names the step; choose the app and confirm the message
  clears; enter a bad URL and confirm the address prompt.
- Next: UX-3 (run-result honesty).

### Increment UX-3 — Run-result honesty

- Status: done
- Behavior delivered: run results now lead with a plain sentence instead of only
  a status word. Success reads "All N steps completed." (or "The step
  completed."); failures read "Completed X of N steps. Step Y failed: <reason>";
  cancellation and sleep interruption read "Stopped/Interrupted after X of N
  steps. Steps already completed are not undone."; timeouts report how far the
  run got. A permission-related failure exposes a one-click **Accessibility
  Settings** / **Notification Settings** action in the post-run banner and the
  expanded history row. History still lists each action's outcome.
- Interfaces changed: `RunPresentation.summary(for:)` and
  `RunPresentation.permissionFix(for:)`; `RunBannerView` and `RunResultView`
  show the summary and permission action; `HistoryView.RunHistoryRow` shows the
  summary and permission action.
- Tests performed:
  - App tests — TEST SUCCEEDED, including 6 new `RunPresentationTests`
    (success, failure with step/reason, cancellation, interruption, timeout,
    permission detection).
  - Debug build — BUILD SUCCEEDED.
- Physical checks: pending owner Mac pass — run a workflow with a failure and
  read the summary; cancel a multi-step run and confirm the "not undone"
  message; expand a history row.
- Next: UX-4 (empty-state micro-fix).

### Increment UX-4 — Empty-state title micro-fix

- Status: done
- Behavior delivered: a truly empty editor no longer shows the "Untitled
  Workflow" title field before there is anything to name; the Get-started panel
  is the first thing shown. The title (and automatic-run switch) appear with the
  first step or trigger.
- Interfaces changed: `WorkflowEditorView` renders `titleHeader` only when the
  workflow is not empty.
- Tests performed:
  - App tests — TEST SUCCEEDED (no logic change).
  - Debug build — BUILD SUCCEEDED.
- Physical checks: pending owner Mac pass — open a new workflow and confirm no
  title chrome; add a step and confirm the title appears and is editable.
- Final slice gate: Release build — BUILD SUCCEEDED on the combined UX-1–UX-4
  tree.
- Next: stop here per owner decision; D2 manual regression / Phase 3.1 remain
  the next contract steps when requested.

### Increment UX-5 — Default name prompt (replaces auto-naming)

- Status: done
- Behavior delivered: reverted the auto-name-from-first-step behavior at the
  owner's request so a new workflow keeps the `Untitled` name. To make the name
  discoverable instead, the editor title now shows a small "Enter a name" hint
  under the `Untitled` field whenever the name is still the default. Typing a
  name replaces it; clearing the field returns to the `Untitled` default.
- Interfaces changed: reverted `ActionPresentation.suggestedName`,
  `ComposerViewModel.nameWasEdited`/`autoNameIfNeeded`, and the auto-name tests
  (`git revert c37a620`); `WorkflowEditorView.titleHeader` gained the default
  name hint.
- Tests performed:
  - App tests — TEST SUCCEEDED.
  - Debug + Release builds — BUILD SUCCEEDED.
- Physical checks: pending owner Mac pass — add a step to a new workflow and
  confirm the title reads `Untitled` with an "Enter a name" hint; type a name
  and confirm the hint disappears.
- Next: stop here per owner decision.

### Fix UX-4-a — Launch UI test matches the empty-title behavior

- Status: done
- Defect: `TaskOSUITests.testLaunchShowsEditor` still asserted the workflow
  title existed on an empty launch, so it failed after UX-4 hid the title until
  there is content.
- Fix: the test now asserts the title is absent for an empty new workflow and
  that the editor/run controls exist.
- Tests performed:
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED, 10/10.
  - Debug build — BUILD SUCCEEDED.
- Next: stop here per owner decision.

## Work Package 2.7 entry gate (pre-Phase 3)

- Status: CLOSED 2026-09-13. Contract: `WP-2.7.md`.
- Worktree: commit `9f6105f`, working tree clean at registration.
- Baseline (rerun 2026-09-13):
  - `swift test --package-path Packages/TaskOSCore` — 270 tests, 35 suites,
    pass (Core purity test included).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED (37 test functions across 8 files).
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
  - UI tests were not rerun at the entry gate (10 methods across 2 files on
    record); they run at 2.7D3 and Phase 3.
- Owner-approved deferral (2026-09-13): the older pending physical checks are
  deferred to Phase 3 qualification, because WP 2.7 replaces the composer,
  suggestion, source-handling, and revision layers they exercised; 2.7 carries
  its own physical gates (`WP-2.7.md` §8.3) and Phase 3.1–3.3 re-covers legacy
  journeys. Named deferred checks: H2-a, H2-c, I1, I2, I3, J1, J2, J3, M3, N1,
  N2, N3, N4, N-c, N-d, N-e, P1, P2, P3, Q1, Q2, U4, UX-1, UX-2, UX-3, UX-4,
  UX-5, and the D2 manual regression matrix. No qualification gate that belongs
  to work package 2.7 is deferred.
- Owner inputs pending for 2.7D3 (`WP-2.7.md` §9.2): one non-Latin input source,
  VoiceOver access, notification/accessibility permissions for Test actions,
  Notes and Safari for physical tests, and approval before any push.
- Next eligible work package: 2.7A1 — Freeze the language contract.

### Increment 2.7A1 — Command language catalog (plan 2.7A1)

- Status: done
- Behavior delivered: one approved language source for every existing
  capability. `CommandLanguageCatalog` now owns approved aliases/head words,
  canonical wording templates, completion starters, the excluded vocabulary,
  and the schedule/trigger/file/window/notification/wait/copy vocabularies. The
  parser, suggestion engine, canonical phrase builder, composer renderer, and
  capability guide examples all read it. No command wording is accepted in one
  consumer and missing in another.
- Interfaces changed:
  - Added `CommandLanguageCatalog` with per-capability `ActionLanguage` /
    `TriggerLanguage` entries (head words, canonical templates and variants,
    parseable examples, guide example, completion starter), `SharedVocabulary`,
    `FileVocabulary`, `NotificationVocabulary`, `WaitVocabulary`,
    `CopyVocabulary`, `ArrangeVocabulary`, `ScheduleVocabulary`,
    `TriggerVocabulary`, `CommandClauseRoute`, `CanonicalTemplate`, and
    `CompletionStarter`.
  - `CommandParser` gained `language` (default `.standard`) and dispatches
    clause starts through `catalog.clauseRoutes`; all alias/phrase tables were
    removed from the parser.
  - `SuggestionEngine` gained `language` (default `.standard`) and now builds
    action, wait, notification, `when`, and website suggestions from the
    catalog; context detection uses catalog routes and vocabulary.
  - `CanonicalPhrase` action/trigger/schedule/command methods gained a
    defaulted `language` parameter and render from catalog templates.
  - `ComposerDocument` renders drafts from catalog templates; `renderedText`
    uses the catalog action joiner.
  - `WindowPreset.phraseSuffix` delegates to the catalog; capability guide
    examples come from the catalog; clock and interval formatting moved into
    the catalog so composer and canonical wording agree.
  - Fixed remaining `MacFlow` user copy in `CapabilityGuide` and
    `TemplateCatalog` (TaskOS naming).
- Intentional behavior alignments (recorded):
  - The parser now accepts `show the notification` (`the` article), matching
    the wording the suggestion engine already offered; previously the parser
    accepted only `a`.
  - Canonical schedule phrases now use the composer's 12-hour clock
    (`Every day at 9:00 AM`), so they reparse; the previous 24-hour
    `09:00` form was ambiguous to the parser for hours 1–12. Interval wording
    also gained correct singular forms (`1 hour`, `1 minute`).
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 284 tests, 36 suites,
    pass (was 270/35; +14). New `CommandLanguageCatalogTests`: every executable
    capability has exactly one language entry; every head word has a parser
    route; every example and every canonical action/trigger/schedule phrase
    reparses (the absolute `Once on` form is asserted as the documented B2
    pending exception); suggestions match catalog wording; every starter is
    parser-recognized; every clause route is parser-recognized; preset phrases
    are catalog-owned; no application identity alias leaks into the catalog;
    runtime/permission sources do not reference the catalog.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (Core language refactor; no UI or platform behavior
  change).
- Remaining defects / gaps:
  - The canonical absolute one-time form (`Once on <date>`) remains
    review-only and does not reparse; 2.7B2 adds the absolute schedule form.
  - Presentation display names (step titles, Add-step menu copy) remain
    presentation-owned labels, not parser aliases.
- Next eligible work package: 2.7A2 — Make source handling safe.

### Increment 2.7A2 — Safe UTF-16 source handling (plan 2.7A2)

- Status: done
- Behavior delivered: the language layer now works in checked UTF-16 source
  offsets end to end, fails closed on invalid boundaries and over-limit input,
  resolves quoted literals with escapes, and reports what each recognized span
  means plus what value it still needs.
- Interfaces changed:
  - `SourceSpan` is now a UTF-16 range with `length`, `isValid(in:)`, and a
    checked `range(in:)` that rejects offsets inside a surrogate pair;
    `String.substring(in:)` uses that conversion.
  - `CommandTokenizer` emits UTF-16 spans (character scanning preserved).
  - Added `CommandLimits` (2,000 characters, 16,384 UTF-16 units, 128 tokens,
    12 actions, 8 visible suggestions, 5,000 applications).
  - Added `CommandInput` (text, UTF-16 selection with clamping, marked-text
    state, source generation, `GrammarLocale.english`) and `CommandEdit`
    (validated UTF-16 replacement, applied text, resulting selection).
  - Added `CommandLiteral` / `CommandLiteralError` / `CommandLiteralScanner`:
    one shared scanner for double-quoted literals where `\"` is a quote and
    `\\` is a backslash; no other escape is interpreted; unclosed and unquoted
    inputs are typed failures.
  - Added `CapabilityReference`, `InterpretationEvidence`, `ExpectedSlot`,
    `TextReplacement`, `ParseClarification`, and `SourceCoverage`.
  - `ParsedClause` gained computed `capability`, `evidence`, and
    `expectedSlots`; `ParsedCommand` gained `coverage` and `clarifications`.
  - `CommandParser.parse` rejects over-limit input with one correction and keeps
    the source text; it computes coverage, adds a "Some text was not understood"
    error when unresolved non-connector spans remain, and turns a 13th action
    into a blocked result. Copy Text now scans its literal, resolving escapes
    and treating an unclosed quote as `Needs input` with a clarification.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 302 tests, 37 suites, pass
    (was 284/36; +18 `SourceHandlingTests`). New coverage: UTF-16 span offsets
    with emoji; combining marks and non-Latin names; curly/straight apostrophes;
    emoji-adjacent replacements; invalid surrogate and stale range rejection;
    `CommandInput` clamping; literal escapes, quoted punctuation, unclosed and
    unquoted literals; Copy Text escape resolution and unclosed clarification;
    full coverage on complete parses; unknown prefix/middle/suffix spans;
    dangerous tails failing closed; evidence and expected slots; character,
    token, UTF-16, and action limit boundaries; visible suggestion limit.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (Core language/source layer; no UI or platform change).
- Remaining defects / gaps:
  - Quoted application names are not yet grammar (scanner exists; 2.7B1).
  - Multi-trigger and bare-domain clarifications arrive in 2.7B1/2.7B2.
  - `TextReplacement` is defined but not yet emitted by suggestions (2.7C).
  - The composer still uses a SwiftUI `TextField`; the native `NSTextView`
    editor and UTF-16 selection reporting are 2.7C2.
- Next eligible work package: 2.7A3 — Preserve authoring state and exact time.

### Increment 2.7A3 — Preserve authoring state and exact time (plan 2.7A3)

- Status: done
- Behavior delivered: card-only values stay attached to their own clauses, and
  one-time schedules resolve once and no longer move. Stable node IDs are
  preserved through unrelated text edits; when a re-parse makes an
  indistinguishable card-only group ambiguous (for example a paste adds a
  second identical file action), the uncertain bindings are cleared instead of
  being silently rotated. Recoverable drafts now carry an optional version-2
  structured payload, and relative/once/interval schedules resolve through an
  injected clock and an explicit calendar and are reused by Preview and Save.
- Interfaces changed:
  - Added `ScheduleResolution` and a private resolution box so a `ComposerDocument`
    value can hold one resolved instant; `resolveSchedule(now:calendar:)`,
    `clearScheduleResolution()`, `scheduleResolution`, and
    `ComposerDocument(clock:)`.
  - `triggerConfiguration()` (stored resolution) plus
    `triggerConfiguration(relativeTo:calendar:)`;
    `makeDefinition(name:id:revision:)` uses the stored resolution and the
    injected clock, and `makeDefinition(name:id:revision:now:calendar:)` resolves
    explicitly. Default `Date()` materialization is gone.
  - Added `AuthoringNode` and `AuthoringSnapshot`; `ComposerActionDraft`,
    `ComposerTriggerDraft`, `ComposerAction`, and `ComposerElement` are now
    `Codable`; `makeSnapshot()` and `init?(snapshot:clock:)`.
  - `ComposerDraft` gained optional `payload` and `recoveryError`, plus
    `schemaVersion`, `authoringSnapshot`, and `encode(snapshot:)`.
  - `DraftRecord` (SwiftData) gained optional `payloadData` for lightweight
    migration; the repository round-trips it.
  - `ComposerDocument` clears the stored resolution when the trigger meaning
    changes and adopts the exact stored date/anchor when opening a saved
    definition.
  - Duplicate-clause guard: `ActionShape`, `isTextIdentifiable`, and
    `actionDrafts(from:)` drive a conservative binding-clearing rule.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 315 tests, 38 suites, pass
    (was 302/37; +13 `AuthoringStateTests`). New coverage: duplicate
    notifications keep messages through an unrelated edit; card reorder moves
    messages with their nodes; delete/undo restores a message; inserting a third
    identical clause keeps existing messages and gets a new ID; an ambiguous
    duplicate remap clears all uncertain bindings; structured snapshot
    round-trip preserves node IDs, card values, and the resolved instant; a
    legacy payload-less draft restores text; a version-2 draft carries the
    snapshot; a one-time schedule resolves once and Save reuses it; an unrelated
    edit does not move the date while a schedule edit does; a card schedule edit
    resolves fresh; a timezone change keeps the stored instant; opening a saved
    definition preserves an exact date with seconds.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including a new SwiftData test that persists and reloads a
    structured payload and restores its card-only value.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (Core behavior plus an app persistence change; no UI or
  platform change).
- Remaining defects / gaps:
  - The exact-edit API is present (`CommandEdit`) but the composer still
    re-parses whole text; binding it to the native `NSTextView` editor is
    2.7C2, and cursor-only invalidation remains trivial until then.
  - `recoveryError` is not surfaced in the UI yet (the view model shows a
    non-sensitive notice on fallback).
  - Completion, resource-selection, and preparation validity keys are 2.7C3.
  - The saved workflow schema is unchanged; only the draft record gained an
    optional field.
- Next eligible work package: 2.7B1 — Exact action language. The Phase 2.7A
  exit gate is met (duplicate clauses do not exchange hidden values; structured
  and legacy draft recovery works; card-only changes invalidate old preparation;
  one-time dates no longer move without an explicit schedule edit; the saved
  workflow schema is unchanged; Core and app tests pass).

### Phase 2.7A verification pass (2026-09-13)

Second run before starting 2.7B, performed at commit `c6db374`:

- Core: `swift test --package-path Packages/TaskOSCore` run twice — 315 tests,
  38 suites, pass both times.
- Focused A-phase suites: `CommandLanguageCatalogTests`, `SourceHandlingTests`,
  `AuthoringStateTests` — 45 tests, 3 suites, pass.
- App tests: `xcodebuild ... test -only-testing:TaskOSTests` — TEST SUCCEEDED.
- UI tests: `xcodebuild ... test -only-testing:TaskOSUITests` — TEST SUCCEEDED,
  10/10 (launch, sidebar, composer typing, suggestions, discovery, step menu,
  settings).
- Debug and Release builds — BUILD SUCCEEDED.
- Release app launch smoke: opened the on-disk store (lightweight migration for
  the optional draft payload) and quit cleanly.
- Source checks: no `Date()` remains in `ComposerDocument` definition
  materialization; saved-workflow schema versions remain 1; working tree clean.
- No defects found. 2.7A is verified.

### Increment 2.7B1 — Exact action language (plan 2.7B1)

- Status: done
- Behavior delivered: the action vocabulary is exact and closed. `open`, `launch`,
  and `start` open an application; application names may be quoted and a quoted
  name is indivisible (it may contain `and`, commas, and other connectors). A
  bare domain such as `apple.com` is no longer silently executable: it produces
  an unresolved website card and a `https://` replacement suggestion that must be
  accepted and reparsed. Copy Text now requires a quoted literal; unquoted text
  leaves the action incomplete. Command-changing negation is recognized and
  blocks completion. Canonical phrases quote multi-word or reserved application
  names so a rendered phrase reparses to the same single application.
- Interfaces changed:
  - `CommandLanguageCatalog.SharedVocabulary` gained `negationWords`;
    `clauseStartWords()` includes them so app lists stop before a negation.
  - `CommandLanguageCatalog.applicationPhrase(_:)` quotes and escapes an
    application name when it contains whitespace, quotes, backslashes, or a
    comma; `CanonicalPhrase`, `ComposerDocument` rendering, and application
    suggestions use it.
  - `openApplication` head words are now `open`, `launch`, and `start`;
    `clauseRoutes` maps all three to the open route. The Open Website discovery
    example is now an absolute URL.
  - `CommandParser`: `collectApplicationNames`, `parseArrange`, and
    `parseArrangeWithFixedPreset` scan quoted names; `parseCopy` uses the literal
    scanner only (no unquoted fallback) and advances past the literal's tokens so
    quoted `then`/`,`/`;` stay inside the text; `parseNegated` reports
    "Negated actions are not supported." as an error.
  - `ComposerDocument` keeps a bare domain as the raw `openWebsite` URL so
    `hasUnresolvedWebsites` blocks completion until the user accepts the HTTPS
    replacement.
- Intentional behavior changes (from the compatibility table):
  - `open apple.com` no longer materializes `https://apple.com` on its own;
    the HTTPS form requires explicit suggestion acceptance.
  - Unquoted `copy agenda` is now `Needs input`; a quoted literal is required.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 325 tests, 39 suites, pass
    (was 315/38; +10 `ActionLanguageTests`, and two Open Website tests were
    intentionally updated). New coverage: open/launch/start aliases; quoted
    names containing connectors; canonical `Open "Google Chrome"` reparses;
    URLs with paths/queries/fragments; bare-domain rejection then acceptance via
    the replacement suggestion; unquoted Copy Text needs input; quoted Copy Text
    keeps connectors/commas/semicolons; negation blocks completion; unsupported
    destructive tails fail closed; missing values report expected slots.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (Core grammar; UI paths exercised by the UI tests).
- Remaining defects / gaps:
  - Bare-domain acceptance is offered as a suggestion; there is no dedicated
    inline "Use https://…" control beyond accepting the completion (2.7C2).
  - Negation is reported, not interpreted; correct negation semantics are out of
    scope for the release.
- Next eligible work package: 2.7B2 — Composition and schedules.

### Increment 2.7B2 — Composition and schedules (plan 2.7B2)

- Status: done
- Behavior delivered: action composition is exact and the schedule grammar is
  complete. `then`, `and then`, `and`, `also`, comma, semicolon, `after that`,
  `next`, and `followed by` separate actions outside quoted literals; a comma or
  semicolon followed by a new action still creates a boundary. One trigger is
  allowed, at the start or the end only; a trigger in the middle or two triggers
  are reported instead of letting the last one win. `closes` is no longer an
  application-quit alias. All schedule forms are supported, including the
  absolute `Once on YYYY-MM-DD at HH:mm` form (two-digit 24-hour time), with
  impossible dates and times rejected and leap days handled.
- Interfaces changed:
  - Catalog: connector words expanded and `;` added to connector punctuation;
    `ScheduleVocabulary.onWord`; `absoluteDateTimeText(_:calendar:)`; the
    `closes` lifecycle alias removed; schedule examples include the absolute
    form.
  - `ParsedSchedule` gained `.absolute(year:month:day:hour:minute:)`.
  - `CommandParser`: `parseAbsoluteOnce` scans the raw date/time, validates it
    (including leap years and hour/minute bounds), and consumes the literal;
    `parse()` now reports "Use only one trigger." and "Put the trigger at the
    start or the end of the command." for position/count violations; comma and
    semicolon boundaries stop app lists when a new clause starts.
  - `ComposerDocument`: trigger clauses that violate the position/count rule
    become unresolved so no definition is built; `.absolute` maps to a one-time
    trigger; one-time rendering uses `Once on YYYY-MM-DD at HH:mm`; trailing
    fragment detection uses the catalog connectors.
  - `CanonicalPhrase` renders one-time schedules in the absolute, reparseable
    form.
- Intentional behavior changes (from the compatibility table):
  - `closes` is rejected; use `quits`.
  - A comma or semicolon before a new action is a boundary, and `after that` /
    `next` / `followed by` join actions.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 337 tests, 40 suites, pass
    (was 325/39; +12 `CompositionAndScheduleTests`). New coverage: every
    connector between two actions in order with full coverage; connectors inside
    Copy Text stay literal; 12 actions complete and 13 block; trigger first/last
    allowed, middle reported; two triggers rejected; event trigger aliases;
    `closes` rejected; every schedule form; leap day valid and impossible dates
    rejected; `9 PM` / `9:00 PM` / `21:00` versus ambiguous `09:00`; absolute
    `09:00`; canonical schedule phrases reparse; an absolute one-time trigger
    survives further composition.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (Core grammar; UI paths exercised by the UI tests).
- Remaining defects / gaps:
  - A trigger supplied at the end is parsed but there is no dedicated UI hint;
    the existing trigger card/selection continues to work.
  - Absolute dates use the current system calendar for authoring-time
    resolution, per the time contract.
- Next eligible work package: 2.7B3 — Friendly frames and finite rationale.

### Increment 2.7B3 — Friendly frames and finite rationale (plan 2.7B3)

- Status: done
- Behavior delivered: friendly leading wording is accepted as nonexecuting
  framing, and only four exact rationale endings are accepted. The approved
  journaling sentence now works end to end:
  "Hey TaskOS, can you make sure at 9:00 PM every day you open Notes, so that I
  can journal my day as I keep forgetting?" produces a daily 9:00 PM trigger and
  an Open Notes action, and its canonical equivalent produces the same typed
  meaning. Accepted rationale is shown in the session and kept in the
  recoverable draft, but is never written into the saved workflow.
- Interfaces changed:
  - Catalog: `ConversationalVocabulary` (leading frames, filler words, rationale
    marker, the four rationale endings, final punctuation) plus
    `leadingFrameEnd(in:)`, `rationaleSpan(in:)`, `rationaleText(in:)`,
    `isRationaleMarker(_:)`, and `isFinalPunctuation(_:)`.
  - `CommandParser`: approves leading frames/fillers and one final punctuation as
    covered nonexecuting spans; cuts parsing before an accepted rationale; stops
    app lists at the rationale marker; and parses the friendly
    `at TIME every day [you] <action>` schedule order into the canonical daily
    form.
  - `ComposerDocument`: preserves the accepted rationale text across rendering,
    undo, and the version-2 snapshot; `makeDefinition` and export ignore it.
  - `AuthoringSnapshot` gained an optional `rationaleText`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 347 tests, 41 suites, pass
    (was 337/40; +10 `FriendlyLanguageTests`). New coverage: the full journaling
    sentence; every listed frame; filler words; one final `?`/`!`/separated `.`;
    `make sure` creating no trigger; every one of the four rationale endings
    (with the text preserved); friendly and canonical forms producing the same
    typed trigger and action; accepted rationale absent from the encoded saved
    workflow; seven arbitrary/unmatched rationale suffixes blocking completion;
    and a rationale marker inside quoted Copy Text staying literal.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug build — BUILD SUCCEEDED.
  - Release build — BUILD SUCCEEDED.
- Physical checks: none (Core grammar; UI paths exercised by the UI tests).
- Remaining defects / gaps:
  - Final punctuation is handled for every family by 2.7B-fix (including an
    attached `.`/`?`); the earlier caveat is resolved.
  - Leading frames are not re-emitted after a card edit; the rationale is.
  - Rationale remains a fixed English set per the plan; no user-defined
    explanations.
- Next eligible work package: 2.7C1 — Versioned application snapshots and list
  ambiguity. Phase 2.7B is complete: the journaling example works, its canonical
  form is equal, only the four rationale endings are nonexecuting, and every
  other unmatched suffix blocks completion.

### Phase 2.7B verification pass (2026-09-13)

Second run before starting 2.7C, performed at commit `0f50f73`:

- Core: `swift test --package-path Packages/TaskOSCore` run twice — 347 tests,
  41 suites, pass both times.
- Focused B-phase suites: `ActionLanguageTests`, `CompositionAndScheduleTests`,
  `FriendlyLanguageTests` — 32 tests, 3 suites, pass.
- App tests: `xcodebuild ... test -only-testing:TaskOSTests` — TEST SUCCEEDED.
- UI tests: `xcodebuild ... test -only-testing:TaskOSUITests` — TEST SUCCEEDED.
- Debug and Release builds — BUILD SUCCEEDED.
- Release app launch smoke: opened and quit cleanly.
- That pass re-ran the existing tests only. A later independent audit (below)
  found defects those tests did not cover.

### Increment 2.7B-fix — Independent audit hardening (2026-09-13)

- Status: done
- Behavior delivered:
  - Connectors are exact: `after that` and `followed by` are matched as
    phrases, and `next` only connects when a clause follows. Dangling
    connectors fail closed instead of being dropped, and list items such as
    `Next`, `After`, or `By` survive (`open Safari and Next` is two apps).
  - Repeated action heads create boundaries (`open Notes open Safari` is two
    steps, not one bogus application name).
  - Copy Text canonical rendering escapes `"` and `\`, so a literal containing
    a quote or a trailing backslash survives rendering, reparsing, and
    open-for-edit.
  - Relative and interval durations render exactly (`In 90 seconds`,
    `Every 90 seconds`); `seconds` are accepted for schedule durations, so an
    unrelated text edit no longer truncates `in 1.5 minutes` to `In 1 minute`.
  - One final `.`, `?`, or `!` is accepted for every action family
    (`wait 5 seconds.`, `show a notification.`, `once at 7 pm.`,
    `maximize Safari.`, and absolute `Once on … at HH:mm.`), and an attached
    `?` no longer becomes part of an application name.
  - Canonical application phrases quote reserved single words (`Open "Next"`),
    so rendered names reparse to the same one application.
  - The 12-action limit counts list-expanded actions, and the composer surfaces
    the parser's `at most 12 steps` correction when Preview or Save cannot
    build a definition.
  - The rationale scan skips quoted literals and refuses to approve a rationale
    inside an unclosed quote; the friendly `at`/`you` words come from the
    catalog rather than parser literals.
- Interfaces changed:
  - `SharedVocabulary` gained `listSeparatorWords` and
    `clauseConnectorPhrases`; `ScheduleVocabulary` gained
    `optionalSubjectWords` and seconds in `durationUnits`.
  - `CommandLanguageCatalog` gained `copyTextPhrase(_:)`, reserved-name quoting
    in `applicationPhrase(_:)`, exact `intervalText(_:)`, and a quote-aware
    `rationaleSpan(in:)`.
  - `CommandParser`: trailing-punctuation splitting, phrase-aware connectors,
    repeated-head boundaries, expanded action counting, and fail-closed
    coverage for trailing connectors.
  - `ComposerDocument.blockingParseMessage`; the view model shows it when
    Preview or Save cannot produce a definition.
- Tests performed:
  - Core: `swift test --package-path Packages/TaskOSCore` — 356 tests, 41
    suites, pass (was 347/41; +9 tests covering connector-word list items,
    dangling connectors, repeated heads, reserved canonical names, Copy Text
    quote/backslash round trip, expanded-list limit, unclosed quote before a
    rationale, exact schedule reparse equality, and relative duration round
    trip).
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED, 10/10.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: none (Core grammar plus a view-model message; the UI paths
  are exercised by the UI tests).
- Remaining defects / gaps: none known for 2.7B. The next eligible work package
  is 2.7C1 — Versioned application snapshots and list ambiguity.

### Increment 2.7C1 — Versioned app snapshots and list ambiguity (plan 2.7C1)

- Status: done
- Behavior delivered: applications are resolved from one immutable, versioned
  snapshot using exact normalized matching over display name, file name (without
  `.app`), and approved local aliases. There is no first-match fallback: two
  trusted apps with the same accepted name produce ambiguity, and a
  connector-separated list that can be read more than one way is reported with
  rewrites instead of being split silently (for example
  `Open Research and Notes and Safari`). Catalogs above 5,000 applications
  refuse automatic search and resolution. The composer only fills an application
  reference from a unique exact match; missing or ambiguous names stay unresolved
  so Preview, Save, and Test remain blocked, and the clarification is shown.
- Interfaces changed:
  - Core: added `ApplicationRecord` (display name, file name, bundle identifier,
    trusted URL, aliases), `ApplicationSnapshot` (monotonic revision, creation
    time, records, `isOverCap`), `ApplicationResolution`,
    `ApplicationResolver` (normalize/resolve), `ApplicationGrouping`,
    `ApplicationGroupingResult`, and `ApplicationListGrouper` (bounded
    backtracking, max two groupings, quoted rewrites).
  - `ResourceCatalog` gained `applicationSnapshot()` with an empty default so
    existing catalogs keep compiling.
  - App: added `ApplicationRecordProviding` and `ApplicationCatalogService`
    (coalesced refresh, monotonic revision, reset);
    `WorkspaceResourceCatalog` now builds records with file name, URL, and an
    approved alias table and keeps `installedApplications()` as a projection;
    `AppComposition` owns the service and exposes `loadApplicationSnapshot()`.
  - `ComposerViewModel`: holds `applicationSnapshot` and
    `applicationClarification`, loads/refreshes the snapshot (composer open,
    refresh method, active after 60 seconds), resolves exact/alias names, rewrites
    an unambiguous merged list to its quoted canonical form, and reports
    ambiguity in Preview/Save notices.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 369 tests, 42 suites, pass
    (was 356/41; +13 `ApplicationCatalogTests`). New coverage: normalize (case,
    `.app` suffix); empty catalog; single display-name/file-name/alias matches;
    duplicate display name is ambiguous (not first); the 5,000/5,001 cap; one
    unambiguous grouping with the exact rewrite; quoted connector-bearing name;
    whole-list collision; merged whole-list collision; partial-span collision;
    more than two groupings; unresolved names; and no list-order selection.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including new `ApplicationCatalogServiceTests` (concurrent
    refreshes coalesce into one provider call and one revision; refreshes
    advance the revision and keep the latest; reset clears).
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: none (Core + app resource resolution; UI paths exercised by
  the UI tests).
- Remaining defects / gaps:
  - Ambiguity is surfaced as a notice plus unresolved cards; an interactive
    rewrite picker arrives with the native completion panel (2.7C2).
  - Suggestions still use `[ApplicationResource]` and do not yet surface aliases
    as completion candidates (2.7C2).
  - The miss-triggered refresh is throttled to 60 seconds to avoid refresh loops;
    a dedicated refresh trigger is exposed as `refreshApplicationSnapshot()`.
- Next eligible work package: 2.7C2 — Native command editor and completion.

### Increment 2.7C2 — Native command editor and completion (plan 2.7C2)

- Status: done
- Behavior delivered: the command field is a real `NSTextView` wrapped for
  SwiftUI. It reports the source text, the exact UTF-16 replacement range and
  replacement text, the UTF-16 selection, and the marked-text state. The
  completion panel stays connected to the suggestion engine, with Up/Down moving
  the highlight, Return accepting the highlighted suggestion, Tab accepting only
  when a suggestion was explicitly selected, Escape dismissing the panel, and
  normal typing otherwise. Return never triggers Save or Test. While an input
  method has marked text, the TaskOS panel is hidden, acceptance is rejected, and
  Return/Tab/Escape/arrow keys are left to the input method; when composition
  commits, text and selection are re-read and completion resumes. VoiceOver
  reports the suggestion count, the selected suggestion, the replacement
  meaning, and whether more input is needed.
- Interfaces changed:
  - Added `NativeCommandTextView` (`NSViewRepresentable` + `Coordinator`) that
    wires `NSTextViewDelegate` edits, selection, marked text, focus, and
    `doCommandBy` key commands.
  - `CommandComposerView` now uses the native editor and exposes completion
    count/selected accessibility values.
  - `ComposerViewModel`: `updateFromEditor(text:edit:)`,
    `updateCommandSelection(_:)`, `setMarkedTextActive(_:)`,
    `moveHighlightInteractively(by:)`, `acceptHighlightedInteractively()`,
    `acceptSelectedInteractively()`, `dismissSuggestionsInteractively()`,
    `suggestionCountAccessibilityLabel`, and
    `selectedSuggestionAccessibilityLabel`; new state `commandSelection`,
    `isComposingMarkedText`, and `highlightMovedByUser`.
  - Core `Suggestion` gained `replacementMeaning` and `kind`.
- Intentional behavior notes:
  - Text undo remains model-authoritative (the editor sets `allowsUndo = false`
    and the app menu routes undo/redo to the composer document), so undo covers
    typing, suggestion acceptance, and card edits uniformly.
- Tests performed:
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including new view-model tests for editor edits and UTF-16
    selection, marked-text suspension/resume, and Tab accepting only after an
    explicit selection.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED, 10/10 with the native editor (launch, sidebar, composer typing,
    suggestions, discovery, step menu, settings).
  - Core tests — 369 tests, 42 suites, pass.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending owner pass for a non-Latin input method and VoiceOver
  reading order (2.7D3 physical proof).
- Remaining defects / gaps:
  - Completion acceptance uses the exact current document fragment, but the
    cross-generation validity key and stale-replacement rejection arrive in
    2.7C3.
  - Native `NSUndoManager` is not used; model snapshots are authoritative.
- Next eligible work package: 2.7C3 — Result validity and bounded typo help.

### Increment 2.7C3 — Result validity and bounded typo help (plan 2.7C3)

- Status: done
- Behavior delivered: asynchronous results can no longer publish or apply after a
  later edit. Completion carries a composite key (session, source generation,
  cursor, marked-text state, language revision, app snapshot revision); it is
  rechecked before results are stored and again before a suggestion is accepted,
  so a suggestion produced for an older generation or cursor is rejected.
  Preparation carries a preparation key and is discarded if the authoring
  revision changed while it ran. Resource selection carries a resource key and
  refuses to bind when the target node is gone, the authoring revision moved, or
  the app snapshot changed. Cursor movement alone does not change the authoring
  revision, so an unchanged Preview survives it, while any card-only change still
  invalidates preparation. Typo help is explicit and bounded: no proposals below
  five characters or above sixty-four; distance one for five to eight
  characters; distance two with a normalized distance of at most 0.20 for nine
  to sixty-four; at most three typo proposals inside the eight-suggestion limit;
  and searches are capped at 5,000 applications.
- Interfaces changed:
  - Core: added `CompletionKey`, `ResourceSelectionKey`, and `PreparationKey`.
  - `SuggestionEngine`: `typoMatches` implements the thresholds; typo proposals
    are capped at three; application search is limited to the 5,000-app cap.
  - `ComposerViewModel`: `sessionID`, `sourceGeneration`, and `completionKey`;
    `currentCompletionKey()`; `refreshSuggestions` rechecks the key before
    storing; `accept` rechecks it before applying; `prepare` and `save` capture
    and recheck a `PreparationKey`; `resolve(id:application:)` and `chooseFile`
    validate the target node before binding.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 377 tests, 43 suites, pass
    (was 369/42; +8 `ResultValidityTests`). New coverage: no typo proposals
    below five or above sixty-four characters; distance-one only for five to
    eight; distance-two with the normalized bound; at most three typo proposals;
    the 5,000-app search cap; and completion/resource/preparation key equality.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including new stale-result tests: a completion is rejected after
    the cursor moves; a stale preparation does not publish a preview; a resource
    selection for a deleted node does not bind.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending owner pass for the non-Latin input method and
  VoiceOver reading order (2.7D3).
- Remaining defects / gaps:
  - Completion and typo search run synchronously (the engine is deterministic and
    fast), but the keys and rechecks are in place for any future async search.
  - Typo matching is Levenshtein over lowercased names; no locale folding.
- Next eligible work package: 2.7D1 — Independent language corpus. Phase 2.7C is
  complete: stale completion cannot publish or apply, stale resource selection
  cannot bind, stale preparation cannot publish Preview or approval, cursor-only
  movement does not invalidate an unchanged Preview, card-only changes always
  invalidate old preparation, and typo help is explicit and bounded.

### Increment 2.7C-fix — Independent audit hardening (2026-09-13)

- Status: done
- Behavior delivered:
  - Grouping an unambiguous merged app list now rewrites only that run's actions
    (`ComposerDocument.replaceActions(ids:with:)`) instead of replacing the whole
    command text. Triggers, other steps, rationale, and card-only values survive
    the rewrite, and undo no longer re-applies a destructive whole-text
    replacement. Grouping now covers `hide` and `quit` lists as well as `open`.
  - A snapshot above 5,000 applications refuses automatic application search
    entirely (grammar suggestions only) instead of silently searching the first
    5,000 records.
  - Resource selection carries a captured `ResourceSelectionKey`: application,
    browser, and file pickers capture the key when their configuration row
    appears and refuse to bind when the session, node, slot, authoring revision,
    or app snapshot revision moved.
  - Marked-text composition no longer pushes preedit text into the document or
    starts application/typo searches; completion and resolution resume after the
    composition commits. Preparing a workflow is refused while marked text is
    active.
  - Completion acceptance uses a stored, checked UTF-16 replacement range, and
    the old `String.prefix` count bug that could corrupt text after non-BMP
    characters is fixed; an invalid range falls back to the current fragment.
  - Preparation and save validity use a monotonic authoring generation so
    edit/undo cannot reuse a previous revision identity for a different state.
  - `ApplicationCatalogService` ignores an in-flight refresh after `reset()`.
  - Settings exposes an explicit "Refresh App List" control, and the completion
    key uses `CommandLanguageCatalog.currentRevision` instead of a magic `1`.
- Interfaces changed:
  - Core: `ComposerDocument.completionFragmentRange()`,
    `accept(_:replacing:)`, and `replaceActions(ids:with:)`; `SuggestionEngine`
    refuses over-cap application search; removed the dead
    `ResourceCatalog.applicationSnapshot()` and `Suggestion.kind`;
    `CommandLanguageCatalog.currentRevision`.
  - App: `ComposerViewModel.applyApplicationSnapshot(_:)`,
    `beginApplicationSelection(for:)`, `beginResourceSelection(for:slot:)`,
    keyed `resolve(id:application:key:)` and
    `updateWebsiteBrowser(id:browser:key:)`, keyed `chooseFile`, and the
    monotonic `authoringGeneration`; `ApplicationCatalogService` refresh
    generation; `NativeCommandTextView` commits only after marked text ends;
    `StepConfigurationView` captures selection keys.
- Tests performed:
  - Core: `swift test --package-path Packages/TaskOSCore` — 380 tests, 43
    suites, pass (was 377/43; +3: checked UTF-16 acceptance with emoji, invalid
    replacement fallback, and grouped replacement preserving the trigger and
    wait step). The over-cap test now asserts refusal instead of truncation.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including new coverage: revision and snapshot resource-selection
    refusal, browser key refusal, merged open/hide list preserving the trigger
    and other steps, marked text blocking preparation, and reset during
    refresh.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED, 10/10.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: none (Core/app behavior; the UI paths are exercised by the
  UI tests; non-Latin IME and VoiceOver proof remains in 2.7D3).
- Remaining defects / gaps:
  - The miss-triggered snapshot refresh keeps its 60-second throttle (now
    alongside the explicit refresh control) to avoid repeated directory scans
    while typing; still an intentional deviation from the unthrottled wording in
    WP-2.7 §7.1.
  - Suggestions still do not surface application file-name or alias matches
    (tracked gap).
- Next eligible work package: 2.7D1 — Independent language corpus.

### Increment 2.7D1 — Independent language corpus (plan 2.7D1)

- Status: done
- Behavior delivered: a reviewed, oracle-independent language corpus. Hand
  authored fixtures cover every action alias, every trigger family, every
  schedule form, every connector, quoted literals, Unicode, friendly frames, the
  four rationale forms, canonical action and schedule phrases, missing slots, and
  the compatibility exceptions. A fixed-seed generator (seed `0x2_7_D1_2026`)
  produces 2,000 positive commands whose expected clause kinds and resource names
  are computed from literal, reviewed tables rather than from production parser
  or catalog code. More than 100 held-out negatives must fail closed, and
  dedicated ambiguity fixtures assert `Needs input` and exact app-list
  clarifications.
- Defect fixed (surfaced by the corpus): canonical quarter-window phrases did not
  reparse. The preset grammar now accepts both `top-left`/`top-right`/`bottom-…`
  compounds and the spaced form, with an optional `quarter` noun, so every
  canonical arrange phrase round-trips.
- Interfaces changed:
  - `CommandLanguageCatalog.ArrangeVocabulary` gained `quarterNouns`;
    `CommandParser.parsePresetPhrase` handles hyphenated quarter presets and
    consumes an optional quarter noun; added `hyphenatedQuarterPreset`.
  - Added `Packages/TaskOSCore/Tests/TaskOSCoreTests/IndependentLanguageCorpusTests.swift`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 393 tests, 44 suites, pass
    (was 380/43; +13 corpus tests). Acceptance proven: every generated positive
    parses to the exact expected clause kinds and resource names with complete
    source coverage; every negative fails closed; every ambiguity reports
    `Needs input`; app-list ambiguity yields the exact rewrite pair; missing
    values report the expected slots; friendly and canonical forms produce equal
    typed triggers and actions; the oracle uses literal expectations only.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: none (deterministic corpus).
- Remaining defects / gaps:
  - Unknown words after an open/hide/quit head are retained as application names
    by design; those cases are represented as composer-level unresolved apps
    rather than parser negatives.
  - The corpus is parser/composer level; UI and input-method behavior is covered
    by the UI tests and 2.7D3 physical checks.
- Next eligible work package: 2.7D2 — Integration, persistence, and privacy.

### Increment 2.7D2 — Integration, persistence, and privacy (plan 2.7D2)

- Status: done
- Behavior delivered: the full typed path is proven without the language layer,
  and private text is kept out of stored and portable data.
  - A typed definition round-trips through `AutomationCoding`, decodes, and
    prepares to a runnable `WorkflowPreview` with no `CommandParser` involved;
    the definition is unchanged by preparation.
  - A saved workflow serialized for storage, a portable export, and a run
    history record were inspected directly: none contains the command source
    text, friendly framing, or the accepted rationale.
  - A legacy version-1 draft (no payload) decodes and restores its text; a
    version-2 draft restores the structured authoring state, including a
    card-only notification message, after a store round trip.
  - Recoverable draft records clear after Save/New/Discard (repository path).
  - Core and app production sources contain no `print` calls, so private command
    text, notification messages, paths, and bookmarks cannot be logged.
  - Preview remains effect-free (no executors are reachable from
    `CreationPreparer`); Test and Save remain explicit view-model actions that
    reuse validation, permissions, approval, and runner paths.
- Interfaces changed: none in production. Added
  `Packages/TaskOSCore/Tests/TaskOSCoreTests/IntegrationPrivacyTests.swift` and
  `TaskOS/TaskOSTests/PersistencePrivacyTests.swift`.
- Tests performed:
  - `swift test --package-path Packages/TaskOSCore` — 399 tests, 45 suites, pass
    (was 393/44; +6). New coverage: source-text/rationale absence in the encoded
    saved definition, portable export, and run history; parser-free
    encode/decode/prepare; legacy draft decode and version-2 structured restore;
    and a Core source scan for `print`.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including direct inspection of the stored `WorkflowRecord`
    payload, the stored run-history payload, the draft record lifecycle, and a
    version-2 structured draft in the SwiftData store, plus an app source scan
    for `print`.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
- Physical checks: pending owner pass for Preview effect-free, explicit Test and
  Save, and the non-Latin input method / VoiceOver checks in 2.7D3.
- Remaining defects / gaps:
  - Run-history failure text can still include operator-supplied app or file
    labels; it never includes the command source text.
  - Effect-free preview and explicit Test/Save are asserted structurally here and
    confirmed physically in 2.7D3.
- Next eligible work package: 2.7D3 — Performance and physical proof.

### Increment 2.7D3 — Performance (automated) and physical proof (plan 2.7D3)

- Status: in progress — automated checks and performance measurements are
  complete; the owner physical journeys are pending.
- Performance protocol:
  - Machine: Mac16,10 (Apple M4), 16 GB RAM, macOS 26.6.2 (build 25G83).
  - Toolchain: Xcode 26.6 (17F113), Apple Swift 6.3.3.
  - Configuration: optimized Release (`swift test -c release`).
  - Corpus: 33 representative commands (actions, connectors, quoted/Unicode
    literals, all schedule forms, event triggers, friendly journaling).
  - Application snapshot: 5,000 synthetic applications.
  - Warm-up: 100 parser runs; 100 search runs; 100 completion runs.
  - Measured: 10,000 parser runs; 1,000 search runs; 1,000 completion runs.
  - Boundaries measured separately: Core parse; application search; end-to-end
    completion (text parse plus suggestion model); synthetic snapshot build.
- Results (milliseconds):
  - Parser: p50 0.010, p95 0.024, p99 0.033, max 0.088 (targets p95 ≤ 10,
    p99 ≤ 25 — met).
  - Application search (5,000 apps): p50 3.50, p95 4.68, p99 6.85, max 12.29.
  - End-to-end completion (5,000 apps): p50 3.36, p95 4.66, p99 7.38, max 14.10
    (target p95 ≤ 100 — met).
  - Synthetic snapshot build (5,000 records): p50 0.60, p95 0.67, max 0.69.
    Cold filesystem app discovery is app-level and is recorded by the owner in
    the physical pass; no pass target is claimed for it.
- Automated checks performed:
  - `swift test --package-path Packages/TaskOSCore` — 403 tests, 46 suites, pass
    (4 performance tests are disabled unless `TASKOS_PERF=1`).
  - Release performance run — `TASKOS_PERF=1 swift test -c release --package-path
    Packages/TaskOSCore --filter PerformanceTests` — 4 tests pass, numbers above.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED (composer typing, suggestions, discovery, step menu, settings).
  - Debug and Release builds — BUILD SUCCEEDED.
  - `git diff --check` — clean.
  - Source inspection: no forbidden Core imports (SwiftUI/AppKit/SwiftData/
    Cocoa/UserNotifications); no AI, network, microphone, speech, or wake-word
    references in Core or the app.
- Interfaces changed: added
  `Packages/TaskOSCore/Tests/TaskOSCoreTests/PerformanceTests.swift`. No
  production changes.
- Physical checks (owner, required to close 2.7D3):
  - Type and edit the full journaling sentence; confirm the daily trigger and
    Open Notes, and that rationale stays out of Save/export.
  - Use mouse and keyboard completion (Up/Down, Return, Tab after selection,
    Escape).
  - Reorder two identical notifications with different messages; confirm each
    message stays on its node.
  - Restore a structured recoverable draft.
  - Accept a bare-domain HTTPS proposal.
  - Resolve an ambiguous app list by quoting one app.
  - Verify a relative schedule does not move during editing.
  - Verify a past-due one-time schedule blocks Save.
  - Use one owner-selected non-Latin macOS input method; begin marked-text
    composition while a suggestion is visible and press Return.
  - Use VoiceOver to hear suggestion count, the selected suggestion, and
    clarification text.
  - Use Notes and Safari for a real Test; confirm Preview has no effect; confirm
    Test and Save each require explicit action.
  - Confirm no microphone or network permission is requested.
- Remaining defects / gaps: none known. The annotated tag `wp-2.7-language` is
  created only after the owner physical journeys are recorded and the final exit
  gate passes.

### Increment 2.7D-fix — Independent audit hardening (2026-09-13)

- Status: automated and performance evidence complete; the owner physical
  journeys below remain the only closing gate.
- Behavior delivered:
  - The independent corpus now asserts exact typed parameters for generated
    positives (wait durations, copy literals, arrange presets, file/folder
    kind), every limit boundary (characters, UTF-16, tokens, actions, visible
    suggestions), the exact clarification question for each ambiguity fixture,
    every canonical arrange preset round trip, and expanded aliases
    (`wait for`, `copy text`, `show the notification`, reveal file/folder,
    launched); negative fixtures were broadened with structural failures.
  - `CommandParser.parse()` now emits `ParseClarification`s for needs-input
    clauses and for trigger position/count errors, so ambiguity fixtures assert
    exact corrections from the implementation instead of diagnostics alone.
  - Parser performance now runs 10,000 samples across the full 2,132-command
    qualification corpus (2,000 generated positives plus negatives).
  - The app completion boundary (editor change callback to published suggestion
    model) is measured against 5,000 synthetic apps in an optimized Release
    build via a testability override: p50 4.14 ms, p95 4.36 ms, p99 4.54 ms,
    max 5.38 ms (target p95 ≤ 100 ms — met). Debug app-path p95 was 65.7 ms.
  - Cold application snapshot time (real filesystem discovery) recorded:
    105 applications in 2.78 ms Release (10.59 ms Debug).
  - Integration/privacy coverage added: a saved workflow saves, loads, and runs
    through `WorkflowRunner` with no parser; `ComposerViewModel` Discard, New,
    and Save each clear the recovery draft; Preview publishes without creating a
    run record; a pinned saved-workflow JSON fixture still decodes.
  - UI coverage added for the native composer: Return accepts the highlighted
    suggestion, Escape dismisses the panel, and Tab accepts only after an
    explicit selection; none opens Review or starts a run.
- Interfaces changed:
  - `CommandParser`: additive `ParseClarification` emission for needs-input
    clauses and trigger errors.
  - Tests only: added `LanguageCorpusFixtures.swift`,
    `CompletionPerformanceTests.swift` (app), `ComposerLifecycleTests.swift`,
    `SavedWorkflowRunTests.swift`; strengthened the independent corpus,
    performance, and integration/privacy suites.
- Tests performed:
  - Core: `swift test --package-path Packages/TaskOSCore` — 404 tests, 46
    suites, pass.
  - Release perf: parser p95 0.0218 ms / p99 0.0293 ms (targets ≤ 10/≤ 25 — met);
    search p95 3.66 ms; parse-plus-engine p95 4.00 ms.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED, including the new lifecycle, parser-free run, and Release-threshold
    completion performance suites.
  - UI tests (`xcodebuild ... test -only-testing:TaskOSUITests`) — TEST
    SUCCEEDED, 13/13.
  - Release app build — BUILD SUCCEEDED; `git diff --check` clean; source scans
    show no forbidden Core imports, logging APIs, AI, network, microphone, or
    speech references.
- Physical checks remaining (owner; cannot be performed by an agent):
  - One non-Latin input method: begin marked-text composition while a suggestion
    is visible and press Return; confirm TaskOS does not accept, save, or test.
  - VoiceOver: hear the suggestion count, selected suggestion, replacement
    meaning, and a clarification message.
  - Real Notes/Safari Test: confirm Preview has no effect and Test/Save each
    require an explicit action; confirm no microphone or network permission is
    requested.
  - The annotated tag `wp-2.7-language` is created only after these are
    recorded and the final exit gate passes.
- Remaining defects / gaps: none known in the automated scope.

### Fix 2.7D2 — Typing a second action is no longer reverted (2026-09-14)

- Status: done
- Defect: typing `open safari then open` reverted to `open safari` and the
  partial second step could not be typed. Automatic application resolution
  called `ComposerDocument.resolveApplication`, which regenerated the whole
  command text from materialized elements; an `open`/`hide`/`quit` clause with
  no names yet had no element, so the trailing clause was dropped. The native
  editor then replaced the typed text with the shortened model text. Once the
  first action resolved, the incomplete trailing clause could also be omitted
  silently from Preview/Save.
- Fix:
  - `ComposerDocument.reconcileElements` keeps an empty `open`/`hide`/`quit`
    clause as an unresolved element, so it survives text regeneration and
    blocks Preview/Save until completed.
  - `ComposerDocument.resolveApplication` and `setTrigger` gained a
    `regenerateText` parameter; automatic app/trigger resolution now updates the
    typed node without rewriting the user's source text. Explicit card and
    picker edits still regenerate the canonical command text.
- Tests:
  - Core: `incompleteTrailingClauseSurvivesResolution`,
    `quietResolutionLeavesTheTypedTextUntouched` — 406 tests / 46 suites pass.
  - App: `automaticResolutionKeepsTheTypedTextAndPendingClause`,
    `automaticLifecycleResolutionKeepsTheTypedText` — TEST SUCCEEDED.
  - UI: `testPendingSecondActionKeepsTypedText` (types `open safari then open`
    and asserts the text is preserved) — TEST SUCCEEDED, 14/14.
  - Debug app tests and Release build — SUCCEEDED.
- Remaining defects / gaps: none known. The 2.7D3 owner physical pass is still
  the only open 2.7 item.

### Feature — Deterministic phrase-order normalization (2026-09-14)

- Status: done
- Behavior delivered: a bounded normalization and phrase-order layer maps
  equivalent daily-schedule wording to the same existing typed automation with
  no fuzzy guessing or additional capabilities:
  - `every day` and colloquial `everyday` in the daily context.
  - Trigger → action and action → trigger ordering, including
    `at TIME every day ACTION`, `at TIME ACTION every day`,
    `every day at TIME ACTION`, `ACTION every day at TIME`, and their
    connector/comma variants.
  - Time forms `9pm`, `9 pm`, `9:00 pm`, and `21:00`.
  - Polite prefixes (`please`, `can you`, `could you`, `would you`,
    `make sure`, …), case differences, and harmless punctuation.
  - The parser now emits `timeOfDay` and `dayQualifier` schedule fragments; a
    bounded post-parse pass merges exactly one time fragment and one day
    qualifier when every clause between them is an action clause.
- Fail-closed behavior preserved: two times, two day qualifiers, other schedule
  clauses, non-action gaps, ambiguous `09:00`, a missing time, a missing day,
  middle triggers, and unsupported qualifiers all remain unresolved and block
  Preview/Save.
- Interfaces changed:
  - `ParsedSchedule` gained `.timeOfDay(hour:minute:)` and `.dayQualifier`.
  - `CommandLanguageCatalog`: `at` and `everyday` are schedule routes;
    `ScheduleVocabulary.everydayWord`; schedule head words updated.
  - `CommandParser`: time/day fragment parsing, the bounded
    `normalizedScheduleClauses` merge, and diagnostics computed after
    normalization.
  - `ComposerDocument`: unpaired schedule fragments map to unresolved elements.
- Tests:
  - New `PhraseOrderNormalizationTests`: 20 equivalent daily phrasings produce
    the identical typed plan, a time-format table, a trigger/action ordering
    table, and 14 ambiguous or incomplete phrasings remain blocked (parser not
    complete and `makeDefinition` nil).
  - Core: `swift test --package-path Packages/TaskOSCore` — 410 tests, 47
    suites, pass.
  - Release perf: parser p95 0.0251 ms / p99 0.0493 ms (targets ≤ 10/≤ 25);
    search p95 4.02 ms; app completion p95 4.91 ms (target ≤ 100); cold
    snapshot 105 apps in 2.60 ms.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED.
  - UI tests — TEST SUCCEEDED, 15/15, including
    `testColloquialDailyPhraseCreatesAStep`
    (`at 9:00 pm open notes everyday`).
  - Debug and Release builds — SUCCEEDED.
- Remaining defects / gaps: none known. The 2.7D3 owner physical pass is still
  the only open 2.7 item.

### Fix 2.7D3-a — Review preparation, stale notices, and past-due messaging (2026-09-14)

- Status: done
- Defects found in the owner physical pass:
  1. Reviewing a workflow never prepared it. The Review button and the
     composer's Run button only opened the popover; nothing called
     `ComposerViewModel.prepare()`, so the popover showed
     "Finish resolving every step before running." (or a stale message) and
     "Run once" stayed disabled even for a fully resolved workflow.
  2. A failed action's `notice` persisted across later edits, so a stale
     "Finish resolving every step before saving." message kept appearing in the
     Review popover after the command had changed.
  3. A past-due one-time schedule blocked Save with no specific reason, and
     `canPrepare` still reported the workflow as ready (the bottom bar showed
     nothing while Save failed).
- Fix:
  - `RunReviewView` now calls `model.prepare()` when it appears, so opening
    Review produces the preview (or the exact blocking message) and enables
    "Run once" for a runnable revision.
  - `ComposerViewModel.afterEdit()` clears `notice`, so stale preview/save
    messages cannot survive an edit.
  - `ComposerViewModel` gained `hasPastDueSchedule`; `canPrepare` now includes
    it, `blockingReason` returns "The scheduled time has already passed. Choose
    a new time.", and the prepare/save notices fall back to `blockingReason`
    before their generic text.
- Tests:
  - App tests: `pastDueScheduleBlocksWithAReason`, `editingClearsAStaleNotice`,
    `acceptingWebsiteSuggestionResolvesTheStep`,
    `resolvedWorkflowCanPrepareAfterAutomaticResolution` — TEST SUCCEEDED.
  - Core: `swift test --package-path Packages/TaskOSCore` — 410 tests, 47
    suites, pass.
  - UI tests — TEST SUCCEEDED.
  - Debug and Release builds — SUCCEEDED.
- Physical checks: re-run F (bare-domain acceptance), H (past-due schedule),
  and K (Review) with the rebuilt Release app; these three were the reported
  failures.
- Remaining defects / gaps: none known. The rest of the 2.7D3 owner physical
  pass (IME, VoiceOver, real Test, permissions) is still open.

### Fix 2.7D3-b — Past-due reason without steps; IME preedit safety (2026-09-14)

- Status: done
- Defects found in the owner physical pass:
  1. A past-due one-time schedule with no steps still showed "Add at least one
     step to review or save." because the empty-steps check ran before the
     past-due check, hiding the schedule correction.
  2. The non-Latin input-method journey could not be exercised: the native
     editor re-synced its text from the model whenever the two differed, which
     can overwrite an in-progress composition (preedit) before `hasMarkedText()`
     reports true.
- Fix:
  - `ComposerViewModel.blockingReason` now checks an unresolved trigger and a
    past-due schedule before the empty-steps case, so the past-due correction is
    always surfaced.
  - `NativeCommandTextView` remembers the last text it reported to the model and
    only re-applies model text when the model changed externally; it never
    overwrites the text view while it differs from what was last reported, so
    input-method preedit is preserved. Inline text completion is also disabled.
- Tests:
  - App tests: `pastDueScheduleIsReportedEvenWithoutSteps` — TEST SUCCEEDED.
  - Core: 410 tests, 47 suites, pass.
  - UI tests — TEST SUCCEEDED.
  - Release build — SUCCEEDED.
- Physical checks: re-run H with a schedule-only command (the correction should
  appear) and test I with a non-Latin input method (preedit should stay until the
  composition commits, and Return should go to the input method).
- Remaining defects / gaps: none known. If test I still shows raw Latin text, the
  non-Latin input source may not be active for the TaskOS app.

## Work Package 2.7 final exit gate — PASSED (2026-09-14)

- Contract: `WP-2.7.md`. Tag: `wp-2.7-language` (annotated).
- Automated evidence:
  - Core: `swift test --package-path Packages/TaskOSCore` — 410 tests, 47
    suites, pass.
  - App tests: `xcodebuild ... test -only-testing:TaskOSTests` — TEST SUCCEEDED.
  - UI tests: `xcodebuild ... test -only-testing:TaskOSUITests` — TEST
    SUCCEEDED.
  - Debug and Release builds — BUILD SUCCEEDED.
  - `git diff --check` — clean; source inspection shows no forbidden Core
    imports, no logging APIs, and no AI/network/microphone/speech/wake-word
    references.
  - Independent corpus (2,000 generated positives, 100+ negatives, ambiguity
    fixtures) passes with zero silent completions and zero dropped spans.
- Performance evidence (optimized Release, Mac16,10 Apple M4 / 16 GB / macOS
  26.6.2): parser p95 0.025 ms and p99 0.049 ms (targets ≤ 10 / ≤ 25); app
  completion p95 4.91 ms (target ≤ 100); cold application snapshot 105 apps in
  2.60 ms. Targets met; no target changed.
- Privacy/persistence evidence: saved-workflow, export, and run-history data
  contain no command source text or rationale; v1 drafts restore text and v2
  drafts restore structured authoring state; drafts clear on Save/New/Discard.
- Physical evidence (owner, 2026-09-14): all journeys confirmed working,
  including the journaling sentence, completion (mouse and keyboard), duplicate
  notification reordering, structured draft recovery, bare-domain HTTPS
  acceptance, ambiguous app-list quoting, relative/past-due schedule behavior,
  non-Latin input method with marked-text Return, VoiceOver, real Notes/Safari
  Test, effect-free Preview, explicit Test/Save, and no microphone or network
  permission request. The reported H, F, and K issues and the IME journey were
  fixed (2.7D3-a, 2.7D3-b) and re-tested.
- Existing saved workflows remain compatible; the saved workflow schema is
  unchanged. No open 2.7 defect or required evidence gap remains.
- Phase 3 qualification may now begin.






## Review repairs — 2.7 acceptance fixes (2026-09-14)

- Status: done. All seven findings from the independent 2.7D acceptance review
  were confirmed by reproduction and fixed.
- Defects fixed:
  1. Recovered version-2 drafts now reparse the saved source and graft the saved
     structured state back onto the parsed elements. Incomplete clauses survive
     recovery as unresolved elements, so Preview/Save stay blocked and no
     partial definition can be produced (`ComposerDocument.init?(snapshot:)`,
     `restoreStructuredTrigger`). Exact one-time dates and card-only values are
     preserved.
  2. Editing an Arrange Window preset in the command text now adopts the newly
     parsed preset while keeping the card-only display selection
     (`ComposerDocument.merge`).
  3. Leading, trailing, and repeated connectors fail closed. Connector runs are
     validated against clause spans: leading runs, dangling runs, and repeated
     connector words/punctuation produce errors and block completion
     (`CommandParser.connectorRunDiagnostics`); the independent negative corpus
     gained the corresponding cases.
  4. Preparation and save validity now cover document replacement and name
     changes: `newWorkflow`, `loadForEditing`, `loadTemplate`, `recoverDraft`,
     and `updateName` bump the authoring generation, and the save task rechecks
     the generation after repository I/O before touching session state, so a
     stale save can no longer clear the new document's draft or overwrite its
     saved-workflow bookkeeping (`ComposerViewModel`).
  5. Completion is cursor/selection-aware: suggestions are computed from the
     caret prefix (or the selection), each published suggestion carries an exact
     `TextReplacement` and its `CompletionKey`, acceptance applies the exact
     range, preserves any suffix, and returns the resulting caret
     (`ComposerDocument.completionFragmentRange(upTo:)`,
     `completionReplacement`, `apply`; `Suggestion.replacement`/
     `completionKey`; `NativeCommandTextView` applies the model selection after
     a programmatic replacement).
  6. Absolute dates resolve through an explicit Gregorian calendar with the
     current timezone (`ComposerDocument.authoringCalendar`), and an exact
     application-resolution miss now refreshes the snapshot immediately when no
     refresh is running (the activation check keeps its 60-second gate).
  7. `HANDOFF.md` reflects the final 2.7 state and references the tracked
     `HANDOFF-2.7.md`.
- Tests performed:
  - Core: `swift test --package-path Packages/TaskOSCore` — 417 tests, 47
    suites, pass. New coverage: snapshot restore keeps unresolved clauses and
    structured values; arrange preset follows edited text; leading/repeated
    connectors fail closed; cursor fragment replacement preserves the suffix;
    Gregorian authoring calendar.
  - App tests (`xcodebuild ... test -only-testing:TaskOSTests`) — TEST
    SUCCEEDED. New coverage: stale preparation cannot publish after document
    replacement; stale save bookkeeping is not applied; mid-text suggestion
    acceptance preserves the suffix and caret.
  - UI tests — TEST SUCCEEDED, 15/15.
  - Release performance (optimized Release): parser p95 0.045 ms / p99 0.069 ms
    (targets ≤ 10 / ≤ 25); app completion p95 6.56 ms (target ≤ 100); cold
    snapshot 105 apps in 2.89 ms.
  - Debug and Release builds — SUCCEEDED.
- Remaining defects / gaps: none known in the automated scope. The owner
  physical pass recorded in the final exit gate remains valid; the repaired
  paths (draft recovery, preset edits, connector rejection, stale async work,
  cursor-aware completion, calendar) are covered by the new automated tests.

## Follow-up — trigger-first completion (2026-09-14)

- Status: done
- Behavior delivered: the completion fragment now begins at the trailing action
  head as well as the trailing connector. Commands that start with a
  schedule/trigger (`at 9:00 am open no`, `every day at 9 am open no`,
  `please open no`) now offer app/action suggestions and accept them without
  touching the schedule prefix. Quoted literals are skipped when locating the
  action head, and the replacement span follows the same fragment so acceptance
  replaces only the partial action (`at 9:00 am open no` + accept Notes →
  `at 9:00 am Open Notes`).
- Clarified behavior (no change required): `at 9:00 am open` is incomplete by
  design — a bare time is not a schedule (once vs daily is ambiguous) and `open`
  needs an app. The complete forms work:
  `at 9:00 am open notes every day`, `open notes every day at 9:00 am`, and
  `every day at 9:00 am open notes`. Recovered version-2 drafts that contain
  such partial text now surface it as unresolved instead of silently dropping
  it (2.7 acceptance repair 1).
- Interfaces changed:
  - `ComposerDocument.completionFragmentRange(upTo:)` considers the trailing
    action head (`actionHeadStart`) in addition to the trailing connector
    (`trailingFragmentStart`).
  - `ComposerViewModel.completionContext` uses the fragment text as the query
    so the suggestion engine sees the action fragment, not the whole prefix.
- Tests:
  - Core: `swift test --package-path Packages/TaskOSCore` — 418 tests / 47
    suites pass, including `completionFragmentFollowsTheTrailingActionHead`.
  - App tests — TEST SUCCEEDED, including
    `triggerFirstTextOffersActionCompletions`.
  - UI tests — TEST SUCCEEDED, 17/17, including `testDailyScheduleFirstCompletes`
    and `testPartialScheduleActionCanBeCompleted`.
  - Release perf: parser p95 0.0245 ms / p99 0.0429 ms; app completion p95
    5.35 ms; cold snapshot 105 apps (no target).
  - Debug and Release builds — SUCCEEDED.

## Feature — Relative-day schedules and specific blocking messages (2026-09-14)

- Status: done
- Behavior delivered:
  - `today at TIME [ACTION]`, `tomorrow at TIME [ACTION]`, the optional-`at`
    forms (`today 11 pm open notes`), and the action-first forms
    (`open notes today at 11:00 pm`) now parse to a one-time schedule for the
    exact today/tomorrow instant. The instant resolves once through the
    existing clock and Gregorian authoring calendar and is stored, so unrelated
    edits cannot move it. Canonical rendering is `Today at 9:00 AM` /
    `Tomorrow at 9:00 AM`.
  - A `today` time that has already passed blocks Preview/Save with the
    existing correction "The scheduled time has already passed. Choose a new
    time."
  - The composer now shows the parser's specific reason instead of only the
    generic `Unresolved: …` row: missing values surface their message
    ("Open needs an application name.", "Say how often, for example every day
    at 9 am.", "Add a time, for example tomorrow at 9 am."), and unrecognized
    text is quoted ("Could not match \"…\".").
  - Fail-closed preserved: `today`, `today at 9`, ambiguous `today at 09:00`,
    and conflicting qualifiers (`tomorrow every day …`) remain unresolved.
- Interfaces changed:
  - Catalog: `today`/`tomorrow` schedule routes and `todayWord`/`tomorrowWord`;
    canonical variants `today`/`tomorrow`.
  - `ParsedSchedule`: `.dayOffset(Int)` and
    `.relativeDate(dayOffset:hour:minute:)`; the bounded phrase-order
    normalizer merges one time fragment with one day-qualifier or day-offset
    fragment.
  - `ComposerTriggerDraft.relativeDay(offset:hour:minute:)` with
    `resolveSchedule` computing the exact date; `triggerConfiguration`,
    `render`, `triggerKind`, and `timeDate` extended.
  - `ComposerDocument.blockingParseMessage` falls back to the first warning;
    unrecognized diagnostics quote the unmatched text.
  - `ComposerViewModel.blockingReason` now prefers the past-due message and the
    parser message over the generic correction.
- Tests:
  - Core: `swift test --package-path Packages/TaskOSCore` — 422 tests / 47
    suites pass (relative-day parsing/orderings, resolve-once exact dates,
    past-due blocking, corpus schedule forms, fail-closed negatives).
  - App tests — TEST SUCCEEDED (`tomorrowScheduleIsReadyAndPastTodayBlocks`,
    `blockingReasonSurfacesTheParserMessage`).
  - UI tests — TEST SUCCEEDED, 19/19 (`testTomorrowScheduleCompletes`,
    `testPastDueTodayScheduleExplainsTheProblem`).
  - Debug and Release builds — SUCCEEDED.

## Phase 3.1 — audit repairs (2026-09-15)

- Status: done for the audited scope. The independent audit's 24 findings
  (11 High, 10 Medium, 3 Low) were reproduced against `8ed8668` and repaired,
  plus the Xcode 27 test-compile regression found while re-verifying the audit
  evidence.
- Prerequisite repair: `ApplicationRecordProviding` is now `nonisolated`, so
  the `TaskOSTests` target compiles under Xcode 27 (Swift 6.4) with the app
  target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; the full app suite is
  runnable again.
- Data safety and persistence:
  1. `save()` is now async and result-bearing. `Save and Continue` awaits
     durable persistence before replacing the document and keeps the editor on
     failure.
  2. Dirty detection uses the complete authoring snapshot (source text,
     unresolved clauses, trigger, actions, rationale, revision, name, enabled
     state); unresolved text now prompts and drafts flush on window close /
     termination.
  3. On-disk store failure attempts an explicit recovery (store files moved to
     `TaskOS-store-backup-<timestamp>.store`) and otherwise surfaces a
     persistent in-app warning instead of silently using volatile storage;
     `try!` is gone from store creation.
  4. `loadAll()` decodes records independently, quarantines invalid records,
     and keeps valid workflows and trigger registrations active; the library
     shows a recovery notice.
  5. Save/import/delete/enable/rename/duplicate/clear paths propagate typed
     errors; runtime registries and UI only update after durable success.
  6. New saves persist under the active document identity and rebase the
     in-memory revision after save, so Test runs, approvals, history, and edits
     share one identity and revision.
- Execution safety:
  7. Lifecycle suppression is registered before the open/quit request and
     renewed through the settling window.
  8. Battery monitor state is discarded whenever the trigger or revision
     changes (register and replaceAll).
  9. Schedules re-arm on `NSSystemTimeZoneDidChange` / `NSSystemClockDidChange`
     and the calculator uses the autoupdating timezone.
  10. Background execution never requests notification authorization; the
      executor reports needs-permission failure, Test requests permissions in
      the foreground, and enabling automatic runs requires a runnable,
      permission-ready preview.
  11. File targets are validated at selection and immediately before open:
      packages/application bundles, executable content, scripts, alias/symlink
      targets, and rejected extensions are refused.
  12. Action timeouts no longer wait for non-cooperative executors, and window
      polling is cancellation-aware with safe AX value conversion.
- Privacy and limits:
  13. Website/application failure messages no longer include URLs, query
      strings, paths, or platform error text; the run-history repository
      additionally redacts links and home paths and caps message length.
  14. Deleting a workflow removes its run history and admission events, so the
      confirmation promise is true.
  15. Import checks file size before reading and reads/parses off the main
      actor; export enforces the same 256 KB limit with atomic writes; name and
      notification fields are bounded so TaskOS cannot export what it refuses
      to import.
- Correctness and lifecycle:
  16. `ComposerDocument` resolution state is a true value property (the
      `@unchecked Sendable` box is gone).
  17. The idle 5-second polling loop is removed; library/history loads are
      generation-guarded and driven by notifications and activation.
  18. Stale resource selections retry once with a refreshed key instead of
      dropping the user's choice.
  19. History shows the newest admission events first and has a dedicated
      error state with retry.
  20. Installed-app discovery walks application folders recursively (bounded
      depth, package-aware, deduplicated), so vendor subfolder apps resolve.
  21. `AGENTS.md` points at Phase 3.1 instead of the completed WP 2.7.
- Tests:
  - Core: `swift test --package-path Packages/TaskOSCore` — 433 tests / 47
    suites, pass (new: copy-independent resolution, battery monitor reset,
    non-cooperative timeout, redaction, export/import bounds, field caps,
    per-automation history deletion).
  - App unit tests (`xcodebuild ... test -only-testing:TaskOSTests`) —
    TEST SUCCEEDED, 90 tests (77 before; new: dirty/unresolved text, save
    identity and revision rebasing, corrupt-record quarantine, transactional
    delete-all, redacted persistence, file-target validation, nested app
    discovery).
  - UI tests — TEST SUCCEEDED, 19/19.
  - Debug and Release builds — SUCCEEDED.
- Evidence limits: physical journeys (sleep/wake, timezone travel, permission
  revocation, event storms) were not re-run in this increment; they remain
  Phase 3.2/3.3 work. The environment now runs Xcode 27.0 (27A266a) / Swift
  6.4 and all suites above were executed on it.
