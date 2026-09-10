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
| 1.1 | Build the typed domain and registry | not started | — | Thin slice of this lands in Increment B (4 capabilities) |
| 1.2 | Build the shared composer | not started | — | |
| 1.3 | Build preparation, preview, and execution | not started | — | Thin slice of this lands in Increment B |
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
