# TaskOS — Agent Instructions

Product contract: `PLAN.md`. WP 2.7 contract: `WP-2.7.md`. Progress ledger:
`PROGRESS.md`.

TaskOS v1 is built incrementally as bounded work packages (plan section 3 and
4.4). The release phases are checkpoints; the numbered work packages are the
unit of work. The current work package is **2.7 (deterministic language
hardening)**; the next eligible sub-increment is **2.7A1**.

## Per-work-package loop

1. Read the work package contract and only the directly affected modules.
2. Implement ONE complete user-visible behavior.
3. Run focused tests plus the relevant platform smoke check.
4. Update `PROGRESS.md`: behavior delivered, interfaces changed, tests and
   physical checks performed, remaining defects/evidence gaps, next eligible
   work package.
5. Commit with a concise message.
6. STOP and hand off. Run full phase gates only at phase boundaries.

## Standing authorization

After a work package passes its focused tests, update `PROGRESS.md` and commit
without asking.

### Commit and push cadence (agreed)

- Commit locally after each bounded sub-increment (e.g. H1, I2, J3) for safety
  and clean history. Local commits are cheap and reversible.
- Push to `origin` and create the annotated phase tag only when a numbered
  sub-phase (2.1, 2.2, 2.3, …) is complete and verified.
- Ask before every push, even at a phase boundary.

Never run without explicit authorization:

- `git push --force`, `git push --force-with-lease`
- `git reset --hard`
- `git clean`
- destructive `git checkout` / `git restore`
- any history rewriting

`git push` is ask-first. Normal local status/diff/add/commit may proceed
without repeated approval.

## Milestones and named history

`main` is the integration branch. Each completed numbered sub-phase gets an
annotated tag so history is understandable later:

- Format: `wp-<plan-id>-<short-slug>` (e.g. `wp-0.4-foundation`,
  `wp-2.3-complete`).
- Work package 2.7 is the exception: its sub-phases 2.7A–2.7D are gated
  internally and are not tagged individually; create the annotated tag
  `wp-2.7-language` once, after the full package's final exit gate passes
  (`WP-2.7.md` §12).
- Tag is created when the sub-phase's work is committed, tested, and verified.
  Sub-increment commits before that remain as untagged local history.
- Push tags explicitly at the phase boundary: `git push origin --tags`
  (`git push` is ask-first).

## Build and test

- Core tests: `swift test --package-path Packages/TaskOSCore`
- App build:  `xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration Debug build`
- Release:    `xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration Release build`

## Constraints

- Deployment target: macOS 14.0 and later. Swift 6 language mode.
- `TaskOSCore` must NOT import SwiftUI, AppKit, SwiftData, or concrete platform
  adapters.
- No AI SDKs, no model/provider integration. No network dependency for creation.
- No shell commands, AppleScript, arbitrary JavaScript, or third-party plugins.
- Do not add comments to code unless asked.
