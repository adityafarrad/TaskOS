# TaskOS — Handoff

**Status:** Phases 0–2 complete. Work package 2.7 (deterministic language
hardening) complete (tag `wp-2.7-language`). **Phase 3.1 — complete system
validation and release-blocking repairs — complete as of 2026-09-15**
(24 audit findings plus the Xcode 27 test-compile regression repaired).
**Next: Phase 3.2 — physical compatibility matrix.**
**Contract:** `PLAN.md` · **Ledger:** `PROGRESS.md` · **Agent rules:**
`AGENTS.md` · **Repo:** `https://github.com/adityafarrad/TaskOS` (branch `main`).
Last repair batch: `2279262`; see `git log -1` for the current tip. Working
tree clean; everything through `2279262` is pushed.

---

## 1. What this is

A native macOS automation app (macOS 14+, Swift 6). Users type a command, get
deterministic autocomplete suggestions, review editable trigger/action cards,
preview and test, then save a local automation that runs manually, on a
schedule, or on a system event. No AI, no network dependency for creation, no
shell/AppleScript/plugins.

Layers (strict):
- **Core** `Packages/TaskOSCore` — typed domain, grammar/parser, suggestions,
  schedule/occurrence math, execution policy, admission, event registry.
  Must not import SwiftUI/AppKit/SwiftData.
- **Application** `TaskOS/TaskOS` — composition, view models, SwiftData
  repositories.
- **Platform** `TaskOS/TaskOS/Platform` — AppKit/IOKit/UserNotifications
  adapters (executors, event sources, permissions, login item).
- **Presentation** `TaskOS/TaskOS/Presentation/` — SwiftUI screens (shell in
  `ContentView.swift`).

---

## 2. Build, run, test

```bash
# Core tests (fast, deterministic)
swift test --package-path Packages/TaskOSCore

# App unit tests
xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS \
  -configuration Debug test -only-testing:TaskOSTests

# UI tests
xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS \
  -configuration Debug test -only-testing:TaskOSUITests

# Debug / Release builds
xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration Debug build
xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration Release build
```

Run the Release app (quit any instance first so stale binaries aren't used):

```bash
pkill -f "TaskOS.app/Contents/MacOS/TaskOS" 2>/dev/null
open "$(ls -dt "$HOME"/Library/Developer/Xcode/DerivedData/TaskOS-*/Build/Products/Release/TaskOS.app | head -1)"
```

Key project facts:
- Bundle id `usuals.com.TaskOS`; deployment target macOS 14.0; Swift 6.
- **App Sandbox is OFF** (`ENABLE_APP_SANDBOX = NO`) so Accessibility window
  control works; Hardened Runtime stays ON. Consequence: app storage lives in
  `~/Library/Application Support/default.store` (SwiftData), not a sandbox
  container.
- Production persistence: SwiftData behind `AutomationRepository`,
  `RunHistoryRepository`, `DraftRepository`, `AdmissionEventRepository`.
- The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and
  `SWIFT_APPROACHABLE_CONCURRENCY = YES`. Test fakes that conform to app
  protocols must account for this (see gotchas).
- KeyboardShortcuts is **not** a dependency (global hotkey deferred).

---

## 3. Current evidence (2026-09-15, Xcode 27.0 / Swift 6.4)

- Core: **433 tests / 47 suites pass** (`swift test --package-path
  Packages/TaskOSCore`), including the purity test.
- App unit tests: **90/90 pass** (`-only-testing:TaskOSTests`).
- UI tests: **19/19 pass** (`-only-testing:TaskOSUITests`); full scheme run
  passed 109/109.
- Debug and Release builds succeed.
- WP 2.7 Release performance (unchanged): parser p95 0.025–0.045 ms (target
  ≤ 10), p99 0.049–0.069 ms (target ≤ 25); app completion p95 5.35–6.56 ms
  (target ≤ 100); cold snapshot 105 apps 2.60–2.89 ms. Protocol in
  `PROGRESS.md` under 2.7D3.
- Physical evidence: the 2.7D3 owner pass is recorded in `PROGRESS.md`
  (journaling, completion, duplicate notifications, draft recovery,
  bare-domain acceptance, ambiguous app lists, schedules, non-Latin IME,
  VoiceOver, real Test, effect-free Preview, explicit Test/Save, no
  mic/network permission). No new physical pass was produced for the Phase 3.1
  repairs — see §5.

---

## 4. Phase 3.1 repairs (2026-09-15)

Independent audit of `8ed8668` reported 11 High, 10 Medium, 3 Low findings.
All were reproduced and repaired, plus an Xcode 27 test-compile regression.

- **Data safety:** awaited result-bearing `save()`; Save-and-Continue persists
  before replacing; full-snapshot dirty detection; explicit persistence
  recovery plus a visible warning instead of silent volatile storage;
  per-record quarantine that keeps valid workflows/triggers alive; error
  propagation before UI/runtime updates; document identity and revision rebased
  after save; observer tokens/draft flush/teardown.
- **Execution safety:** suppression registered before open/quit and renewed
  after; battery monitors reset on trigger/revision change; schedules re-arm on
  timezone/clock change; no background permission prompts (foreground Test
  requests; enabling requires a runnable, permission-ready preview); file
  targets reject packages/executables/scripts/aliases; bounded action timeouts
  that do not wait for non-cooperative executors; cancellation-aware window
  polling; validated AX casts.
- **Privacy/limits:** run-history failures redact URLs/paths and cap length;
  workflow deletion cascades to run history and admission events; import reads
  off the main actor after a size precheck; export enforces the same 256 KB
  limit atomically; name/notification fields bounded.
- **Correctness/lifecycle:** `ComposerDocument` value semantics (no
  `@unchecked Sendable` box); idle 5-second polling removed with
  generation-guarded refreshes; stale resource selections retry once; history
  ordering fixed with a dedicated error state; recursive bounded app
  discovery; `AGENTS.md` updated.

Commits: `669c5f3` (Core), `9855236` (app + tests), `2279262` (docs).

---

## 5. What is pending

### Phase 3.2 — physical compatibility matrix (next)
Physical runs on: macOS 14, 15, and 26; Apple silicon and Intel; laptop and
desktop; single and multiple displays with different scaling/positions;
external-storage reconnect; battery/external-power transitions; Accessibility
and notification permission denial/revocation; login-item disablement; sleep,
wake, relaunch, and interrupted runs; standard and multi-window application
behavior. Declared app matrix: Safari, Notes, Finder, TextEdit, a Chromium
browser, and an Electron app. Include the legacy owner-deferred checks:
H2-a, H2-c, I1–I3, J1–J3, M3, N1–N4, N-c/N-d/N-e, P1–P3, Q1–Q2, U4,
UX-1…UX-5, and the D2 manual regression matrix, plus fresh physical checks for
the Phase 3.1 repairs (timezone travel, permission revocation, event storms,
sleep/wake with pending schedules, multi-display Arrange, kill/relaunch with an
in-flight save).

### Phase 3.3 — usability, accessibility, performance
Fresh usability round with ≥ 8 representative users on the plan's task list;
keyboard/VoiceOver operability; latency; **idle CPU < 1% averaged over 30
minutes and no polling loop**; idle resident memory < 200 MB; main window
interactive within two seconds on the baseline machine.

### Phase 3.4 — beta
Minimum two-week beta with ≥ 10 users; collect and classify findings; no
automatic content telemetry.

### Phase 3.5 — distribution and updates
Developer ID signing, Hardened Runtime, notarization + stapling, DMG install
flow, Sparkle update integration with signed HTTPS artifacts, update
consent/settings, release notes/privacy/known-limitations/support. Test a
genuine older signed build upgrading to the release candidate, including
interrupted downloads and invalid signatures; do not install an update while a
workflow is running.

### Phase 3.6 — freeze and release
Final freeze, release notes, and distribution.

### Open engineering gaps (tracked, not blockers)
- Stale file bookmark resolves but is not refreshed back into storage.
- Multi-window Arrange ambiguity fails with a message; no disambiguation UI.
- Whole-workflow timeout returns at the deadline, but a hung Accessibility
  call inside an adapter is not independently interruptable.
- Discovery sheet does not deep-link a missing resource to its card control.
- Admission-event retention constants (200 events / 30 days) are not
  user-configurable.
- Plan-level deferrals: global hotkey (needs KeyboardShortcuts),
  specific-volume card selection, full-screen/Spaces window operations.
- Phase 0.2 autocomplete user validation and Phase 0.5 distribution access
  remain folded into Phases 3.3/3.5.

---

## 6. Important entry points

- Composition root: `TaskOS/TaskOS/AppComposition.swift`
- Composer/view-model: `TaskOS/TaskOS/WalkingSliceViewModel.swift`
- UI: `TaskOS/TaskOS/Presentation/` (`CommandComposerView.swift`,
  `WorkflowEditorView.swift`, `StepCardView.swift`, `InspectorView.swift`, …);
  shell in `TaskOS/TaskOS/ContentView.swift`; menu bar
  `MenuBarViewModel.swift` / `MenuBarContent.swift`
- Runtime: `Packages/TaskOSCore/Sources/TaskOSCore/RunCoordinator.swift`
- Events: `EventTriggerRegistry.swift`, `EventTriggers.swift`,
  `LifecycleSuppressor.swift`; platform sources in `Platform/*TriggerSource.swift`
- Scheduling: `ScheduleTrigger.swift`, `ScheduleRegistry.swift`
- Parser/grammar: `CommandParser.swift`, `ParsedCommand.swift`,
  `ComposerDocument.swift`
- Portability: `WorkflowPortability.swift`; history redaction:
  `RunRecordRedaction.swift`
- Repositories: `Platform/SwiftData*Repository.swift`
- File safety: `Platform/FileTargetValidation.swift`, `FileTargetResolver.swift`
- Permissions: `Platform/SystemPermissionStatusProvider.swift`,
  `NotificationPermission.swift`, `AccessibilityPermission.swift`

---

## 7. Working agreements / gotchas

- **Commit** after each bounded sub-increment locally; **push and tag** only at
  a numbered phase boundary, and **ask before every push** (`AGENTS.md`).
- Xcode 27 note: the CLT shims can report an unaccepted license even when the
  system plist shows agreement; `xcrun <tool>` (or the real binaries under
  `/Applications/Xcode.app/Contents/Developer/usr/bin/`) works. Do not
  "fix" this with `try!` or by weakening test isolation.
- App target default isolation is `MainActor`; new app protocols consumed by
  test doubles should be `nonisolated` (or the doubles `@MainActor`), or the
  test target will not compile under Swift 6.4.
- SwiftData in-memory container creation can flake on the first app-test run;
  suites are `.serialized` and a rerun usually passes.
- Always relaunch the app after a rebuild — earlier confusion came from running
  a stale binary.
- macOS reports Accessibility trust slightly after the app reactivates; the UI
  re-checks ~1.2s after activation.
- Do not add code comments unless asked. `TaskOSCore` must stay free of
  SwiftUI/AppKit/SwiftData.

---

## 8. Documentation map

| File | Purpose | Status |
|---|---|---|
| `PLAN.md` | Product contract, phases, acceptance criteria | Active |
| `PROGRESS.md` | Work-package ledger and evidence | Active |
| `AGENTS.md` | Agent instructions and working agreements | Active |
| `HANDOFF.md` | This document — current state and pending work | Active |
| `WP-2.7.md` | Completed WP 2.7 contract (historical reference) | Retired |
| `HANDOFF-2.7.md` | Superseded 2.7 handoff | **Deleted** |
