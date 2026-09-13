# TaskOS — Handoff

**Status:** Phases 0–2 complete; pre-Phase-3 hardening and UI redesign done.
Work package 2.7 (deterministic language hardening) is registered and next;
Phase 3 not started.
**Contract:** `PLAN.md` · **WP 2.7 contract:** `WP-2.7.md` · **Ledger:**
`PROGRESS.md` · **Agent rules:** `AGENTS.md`
**Repo:** `https://github.com/adityafarrad/TaskOS` (branch `main`)
**HEAD:** `9f6105f` plus the WP 2.7 registration commit (working tree clean)

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
- KeyboardShortcuts is **not** a dependency (global hotkey deferred).

---

## 3. Current evidence

- Core: **270 tests / 35 suites pass** (includes a purity test forbidding
  SwiftUI/AppKit/SwiftData in Core); rerun 2026-09-13 at `9f6105f`.
- App tests: TEST SUCCEEDED (37 test functions / 8 files), rerun 2026-09-13.
- Debug + Release builds clean, rerun 2026-09-13.
- Physical checks: Phase 1 canonical journey; 2.1 schedule tests A–E; 2.4 all
  six event-trigger families; 2.6 attention/retention/permissions UI — all
  user-confirmed. Older pending physical checks (I, J, M3, N1, P, Q,
  N-c/N-d/N-e, U4, UX-1…UX-5, and the D2 matrix) were owner-deferred to Phase 3
  on 2026-09-13; the named record is in `PROGRESS.md` under "Work Package 2.7
  entry gate (pre-Phase 3)".

---

## 4. What is implemented

**Phase 0/1 (foundation + first workflow):** typed registry (Manual, Open App,
Open Website, Arrange Window, Wait, Show Notification), grammar/parser + spans,
suggestion engine, composer document with text/card sync, undo/redo, draft
autosave, preview/approval bound to a revision, sequential execution with
timeouts/cancel, library (search/rename/duplicate/edit/delete/run), menu-bar
runtime, settings/permissions, launch-at-login, interrupted-run recovery,
onboarding.

**Phase 2:**
- **2.1 Scheduling:** one-time/daily/weekdays/interval triggers, next-three
  preview, DST/time-zone policy, admission coordinator (one-at-a-time, 10-run
  queue, 30s expiration, 10s cooldown, duplicate suppression), pause/resume,
  cancel, session readiness, launch-time re-registration.
- **2.2 Actions:** Hide Application, normal Quit (never force; protected apps
  rejected), Copy Text, all window presets, specific-display selection,
  notification editing + presenter delegate.
- **2.3 Files:** explicit file/folder selection, Open File, Reveal in Finder,
  durable bookmark-backed references, missing-resource repair, portable
  JSON export/import with rebinding and disabled defaults.
- **2.4 Events:** application launch/quit (+ lifecycle loop suppression), wake,
  display connect/disconnect, external volume mount/unmount, power source,
  battery threshold (two-point rearm), with discovery/availability.
- **2.5 Templates/discovery:** twelve curated templates, template picker,
  capability discovery sheet (examples, permissions, limitations, availability).
- **2.6 Management:** skipped/queue event visibility, library attention/Fix,
  expanded action-level history, retention (30 days / 1,000 runs), permission
  settings shortcuts.

**Pre-Phase-3 hardening:** editing preserves card-only values; manual runs route
through admission; admission events persisted; import display mapping; domain
URL suggestion.

---

## 5. Important entry points

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
- Portability: `WorkflowPortability.swift`
- Repositories: `Platform/SwiftData*Repository.swift`

---

## 6. Deferred gaps (recorded, intentional)

**Before/around Phase 3:**
- **Legacy pending physical checks** — owner-deferred to Phase 3 on 2026-09-13;
  the named list and reason are in the `PROGRESS.md` 2.7 entry-gate record.
- **Gap 4 — malformed-record isolation/recovery.** `loadAll` throws for the whole
  list if one record fails to decode; no per-record recovery UX. Deferred to
  Phase 3 migration fixtures.

**Smaller:**
- Stale file bookmark resolves but isn't refreshed back into storage.
- Multi-window Arrange ambiguity fails with a message; no disambiguation UI.
- Whole-workflow timeout is between actions; a hung Accessibility call isn't
  independently interruptable.
- Discovery sheet doesn't deep-link a missing resource to its card control.
- Admission-event retention constants (200 / 30 days) not user-configurable.

**Plan-level deferrals:** global hotkey trigger (T2, needs KeyboardShortcuts);
specific-volume card selection; full-screen/Spaces window operations.

---

## 7. Next step: Work package 2.7

Start with **2.7A1 — Freeze the language contract** (`WP-2.7.md`): the
capability-language matrix and `CommandLanguageCatalog`; the plan/ledger/handoff
registration itself is already delivered by the registration commit. Work
through 2.7A → 2.7B → 2.7C → 2.7D in order; no phase starts before the previous
phase's exit gate passes. The full package (tag `wp-2.7-language`) must close
before broad Phase 3 qualification.

Then **Phase 3** (`PLAN.md`): 3.1 system validation (includes the deferred
legacy physical checks), 3.2 physical compatibility matrix, 3.3
usability/accessibility/performance, 3.4 beta, 3.5 distribution (Developer ID
signing, notarization, Sparkle), 3.6 freeze.

---

## 8. Working agreements / gotchas

- **Commit** after each bounded sub-increment locally; **push + tag** only when a
  numbered sub-phase completes, and **ask before every push** (`AGENTS.md`).
  Work package 2.7 is the tag exception: one `wp-2.7-language` tag after the full
  package passes.
- SwiftData in-memory container creation can flake on the first app-test run;
  suites are `.serialized` and a rerun usually passes.
- Always relaunch the app after a rebuild — earlier confusion came from running a
  stale binary.
- macOS reports Accessibility trust slightly after the app reactivates; the UI
  re-checks ~1.2s after activation.
- Do not add code comments unless asked.
