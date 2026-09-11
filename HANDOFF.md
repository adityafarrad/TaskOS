# TaskOS / MacFlow v1 — Handoff

**Status:** Phases 0–2 complete and physically verified; pre-Phase-3 hardening
done. Phase 3 not started.
**Contract:** `PLAN.md` · **Ledger:** `PROGRESS.md` · **Agent rules:** `AGENTS.md`
**Repo:** `https://github.com/adityafarrad/TaskOS` (branch `main`)
**HEAD:** `3b6dfbe` (synced with `origin/main`, working tree clean)

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
- **Presentation** `TaskOS/TaskOS/ContentView.swift` — SwiftUI screens.

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

- Core: **265 tests / 34 suites pass** (includes a purity test forbidding
  SwiftUI/AppKit/SwiftData in Core).
- App tests: SwiftData workflow/history/draft/admission repositories pass.
- Debug + Release builds clean.
- Physical checks: Phase 1 canonical journey; 2.1 schedule tests A–E; 2.4 all
  six event-trigger families; 2.6 attention/retention/permissions UI — all
  user-confirmed.

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
- UI: `TaskOS/TaskOS/ContentView.swift`; menu bar
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

## 7. Next step: Phase 3

Start with **3.1 system validation** (`PLAN.md` §3.1):
full deterministic suites, parser/suggestion corpus, text/card/template parity,
persistence/migration fixtures (fold in Gap 4), runtime interruption/event-storm
tests, Release UI journeys, architecture review.

Then 3.2 physical compatibility matrix, 3.3 usability/accessibility/performance,
3.4 beta, 3.5 distribution (Developer ID signing, notarization, Sparkle), 3.6
freeze.

---

## 8. Working agreements / gotchas

- **Commit** after each bounded sub-increment locally; **push + tag** only when a
  numbered sub-phase completes, and **ask before every push** (`AGENTS.md`).
- SwiftData in-memory container creation can flake on the first app-test run;
  suites are `.serialized` and a rerun usually passes.
- Always relaunch the app after a rebuild — earlier confusion came from running a
  stale binary.
- macOS reports Accessibility trust slightly after the app reactivates; the UI
  re-checks ~1.2s after activation.
- Do not add code comments unless asked.
