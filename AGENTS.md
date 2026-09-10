# TaskOS — Agent Instructions

Product contract: `PLAN.md`. Progress ledger: `PROGRESS.md`.

MacFlow v1 is built incrementally as bounded work packages (plan section 3 and
4.4). The release phases are checkpoints; the numbered work packages are the
unit of work.

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

Never run without explicit authorization:

- `git push --force`, `git push --force-with-lease`
- `git reset --hard`
- `git clean`
- destructive `git checkout` / `git restore`
- any history rewriting

`git push` is ask-first. Normal local status/diff/add/commit may proceed
without repeated approval.

## Milestones and named history

`main` is the integration branch. Each completed work package gets an annotated
tag so history is understandable later:

- Format: `wp-<plan-id>-<short-slug>` (e.g. `wp-0.4-foundation`,
  `wp-1.1-domain-registry`).
- Tag is created after the work package's commit passes its focused tests.
- Push tags explicitly: `git push origin <tag>` (`git push` is ask-first).

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
