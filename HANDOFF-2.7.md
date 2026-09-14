# TaskOS — Work Package 2.7 Handoff

**Status:** Work Package 2.7 (Deterministic Language Hardening) is **complete and
verified**. Branch `main` is at `792156d`; the annotated tag
`wp-2.7-language` is created and pushed.
**Contract:** `PLAN.md`, `WP-2.7.md`. **Ledger:** `PROGRESS.md`.
**No commit or push was made for this document.**

---

## 1. What was delivered

The existing deterministic path was hardened without a new engine:

> Command text → parser → composer document → trusted resource resolution →
> typed automation definition → preparation → preview/approval → runner

### 2.7A — Source handling, language contracts, authoring state
- `CommandLanguageCatalog`: one approved source for aliases, canonical wording,
  completion starters, discovery examples, vocabularies, and schedule/trigger
  phrase tables. Parser, `SuggestionEngine`, `CanonicalPhrase`,
  `ComposerDocument` rendering, and `CapabilityGuideCatalog` consume it.
- Checked UTF-16 source model: `SourceSpan`, `CommandInput`, `CommandEdit`,
  `CommandLimits` (2,000 chars / 16,384 UTF-16 / 128 tokens / 12 actions / 8
  suggestions / 5,000 apps), a shared quoted-literal scanner (`\"`, `\\`), full
  source coverage, and evidence/expected-slot/clarification parse results.
- Stable authoring nodes, conservative duplicate-binding clearing, version-2
  structured draft payload with version-1 text fallback, and resolve-once
  one-time/relative/interval schedules through `CoreClock` + an explicit
  calendar (exact `Date` preserved; no default `Date()` in materialization).
- Saved workflow schema unchanged; only the recoverable draft record gained an
  optional payload field.

### 2.7B — Exact grammar, composition, friendly wording
- Exact action families and aliases (`open`/`launch`/`start`, quoted app names,
  absolute HTTP(S) URLs, quoted-only Copy Text, negation blocks).
- Bare domains are no longer executable: they produce an unresolved website plus
  an `Open https://…` replacement suggestion that must be accepted and reparsed.
- Connectors (`then`, `and then`, `and`, `also`, comma, semicolon,
  `after that`, `next`, `followed by`), one trigger at the start or end only,
  `closes` removed, and all schedule forms including absolute
  `Once on YYYY-MM-DD at HH:mm`.
- Friendly frames/fillers and exactly four rationale endings; the journaling
  sentence works; accepted rationale stays in the session/draft but never enters
  saved workflows, history, or exports.

### 2.7C — Trusted resolution, native editor, validity
- Versioned `ApplicationSnapshot` service with exact resolution over display
  name / file name / approved aliases, ambiguity instead of first-match, bounded
  list grouping with quoted rewrites, and the 5,000-app cap.
- `NativeCommandTextView` (`NSTextView`) with UTF-16 edit/selection/marked-text
  reporting, keyboard completion (Up/Down, Return, Tab only after explicit
  selection, Escape), marked-text suspension, and VoiceOver labels.
- Validity keys for completion, resource selection, and preparation; stale
  results cannot publish or bind; cursor-only movement does not invalidate an
  unchanged Preview; bounded typo help.

### 2.7D — Qualification
- Independent language corpus (2,000 seeded positives, 100+ held-out negatives,
  ambiguity fixtures, literal oracle).
- Integration/persistence/privacy checks (parser-free run path, direct
  serialized-record inspection, v1/v2 draft restore, no private text in records,
  exports, or logs).
- Release performance targets met; owner physical pass confirmed all journeys.

---

## 2. Key history

| Commit | Work |
|---|---|
| `128d1eb` | Register 2.7 contract and entry gate |
| `6b099e2` | 2.7A1 language catalog |
| `9b258c3` | 2.7A2 UTF-16, limits, coverage |
| `c6db374` | 2.7A3 authoring state, draft v2, exact time |
| `30b7272` | 2.7A verification |
| `0d5fd89` | 2.7B1 exact action language |
| `aeadefa` / `5f4981c` | 2.7B2 composition and schedules |
| `0f50f73` | 2.7B3 friendly frames and rationale |
| `d86ec16` | 2.7B verification |
| `ee41c9c` | 2.7B audit hardening (owner) |
| `b3e8f1f` | 2.7C1 app snapshots and ambiguity |
| `360647c` | 2.7C2 native editor and completion |
| `3ba61bf` | 2.7C3 validity keys and typo help |
| `f8d05b7` | 2.7C audit hardening (owner) |
| `b41f61b` | 2.7D1 independent corpus (+ quarter preset fix) |
| `f301262` | 2.7D2 integration and privacy |
| `0393899` | 2.7D3 performance (automated) |
| `72b134a`, `0f94130`, `a472c81`, `d68c1de` | 2.7D audit hardening, partial-clause fix, phrase-order normalization (owner) |
| `70425aa` | Review preparation, stale notices, past-due messaging |
| `937ff6e` | Past-due without steps; IME preedit safety |
| `792156d` | Close final 2.7 exit gate; tag `wp-2.7-language` |

---

## 3. Verification evidence

- **Core:** `swift test --package-path Packages/TaskOSCore` — 410 tests / 47
  suites pass.
- **App tests:** `xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS
  -configuration Debug test -only-testing:TaskOSTests`.
- **UI tests:** `... test -only-testing:TaskOSUITests` — pass.
- **Builds:** Debug and Release build clean.
- **Performance (Release, Mac16,10 Apple M4 / 16 GB / macOS 26.6.2):** parser
  p95 0.025 ms, p99 0.049 ms (targets ≤ 10 / ≤ 25); app completion p95 4.91 ms
  (target ≤ 100); cold snapshot 105 apps in 2.60 ms.
- **Privacy:** saved workflows, exports, and run history contain no command
  source text or rationale; Core and app sources contain no `print`.
- **Physical (owner, 2026-09-14):** all journeys confirmed, including journaling,
  completion, duplicate notifications, draft recovery, bare-domain acceptance,
  ambiguous app lists, schedules, non-Latin IME, VoiceOver, real Test,
  effect-free Preview, explicit Test/Save, and no mic/network permission.

---

## 4. Issues found in the physical pass and fixed

- **F/K (Review did nothing):** the Review popover never called `prepare()`;
  `RunReviewView` now prepares on appear.
- **K (stale notice):** `notice` persisted across edits; `afterEdit()` clears it
  and prepare/save fall back to `blockingReason`.
- **H (past-due):** `canPrepare`/`blockingReason` now surface a past-due
  one-time schedule, including when there are no steps.
- **I (IME):** the editor no longer overwrites the text view from the model when
  they differ (protects in-progress preedit); inline text completion disabled.

---

## 5. Known gaps (tracked, not blocking)

- Ambiguity is a notice plus unresolved cards, not an interactive rewrite picker.
- Suggestions do not surface application file-name/alias matches.
- Miss-triggered snapshot refresh is throttled to 60 seconds (explicit
  `refreshApplicationSnapshot()` exists; Settings has "Refresh App List").
- Run-history failure text can include operator-supplied app/file labels; it
  never includes command source text.
- Global hotkey (T2) remains deferred; `admission events` persistence and Gap 4
  (malformed record isolation) remain Phase 3 items.

---

## 6. Next step

Phase 3 starts at **3.1 system validation** (`PLAN.md` §3.1). The 2.7 tag is the
qualification baseline. Ask before any push.
