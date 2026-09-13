# Work Package 2.7 — Deterministic Language Hardening

**Status:** contract registered; implementation not started.
**Placement:** pre-Phase-3 work package. Phase 3 qualification begins only after
2.7 passes its final exit gate.
**Baseline:** commit `9f6105f` (Core baselines rerun 2026-09-13).
**Source material:** owner-supplied WP 2.7 plan (2026-09-13), grounded in the
MacFlow Language Architecture and Implementation Blueprint v1.0 (12 September
2026), chapters 1 (architecture), 6 (catalog), 12 (safety), and 16 (failure
modes). This document is self-contained; it does not depend on external files.

This is not a new compiler, workflow engine, store, or runtime. The existing
path remains authoritative:

> Command text → parser → composer document → trusted resource resolution →
> typed automation definition → preparation → preview and approval → existing
> runner

Naming note: this work package is unrelated to `PLAN.md` §2.7 ("Screens and
lifecycle"). Work-package and product-section numbers are separate namespaces
already used side by side in `PLAN.md`.

---

## 1. Summary and fixed decisions

Work package 2.7 must be completed before more action families, trigger
families, or broad Phase 3 qualification begin.

- Use the name TaskOS everywhere. (MacFlow survives only in the titles of
  historical external source material, not in active project documentation.)
- Support macOS 14 and later.
- Use Swift 6.
- Keep `TaskOSCore` free of SwiftUI, AppKit, SwiftData, and platform adapters.
- Keep creation deterministic and offline.
- Do not add AI models, semantic matching, speech recognition, or wake words.
- Do not add network dependencies.
- Do not add shell commands, AppleScript, JavaScript, or plugins.
- Do not add new action or trigger families.
- Do not add conditions, branches, parallel actions, or multiple-trigger
  workflows.
- Keep the existing typed workflow, repository, approval, and execution paths.
- Keep recoverable drafts.
- Saved workflows, run history, and exports must not contain command text,
  rationale text, parser evidence, or transcripts.
- Recoverable drafts may contain source text and unsaved card values. This is
  required so editing and recovery do not lose work.
- All parsing must fail closed. Unknown, ambiguous, incomplete, or partly
  supported input must not create a complete automation.
- Preview, Save, and Test remain disabled until syntax, trusted resources, and
  all required card values are complete.

The blueprint's main rules remain in force: extend the existing path, separate
language metadata from executable capabilities, preserve safety and approval,
and guard against stale asynchronous results and invalid text ranges.

### 1.1 Current executable capability set (do not extend)

Actions: Open Application, Hide Application, Quit Application, Open Website,
Open File (file or folder), Reveal in Finder, Arrange Window, Wait, Show
Notification, Copy Text.

Triggers: Manual, Schedule, Application Lifecycle, Wake, Display Connection,
External Volume, Power Source, Battery Threshold. (Global hotkey remains
deferred by owner decision and is out of scope.)

The language plan below adds wording, not capabilities.

---

## 2. Compatibility rules

Safe old commands must keep the same typed meaning. The following intentional
safety changes are exceptions:

| Old behavior | Required 2.7 behavior |
|---|---|
| A bare domain may become an HTTPS URL automatically. | Offer an HTTPS replacement. Apply it only after the user accepts it. |
| More than one trigger may result in one trigger winning. | Report a clarification. Do not create a definition. |
| Unquoted Copy Text content may be accepted. | Require quoted literal text. |
| Two installed apps with the same display name may select the first result. | Report ambiguity. Require a clear choice. |
| `closes` may mean that an app quits. | Stop accepting this alias. Ask the user to use `quits`. |
| Unknown trailing words may be ignored. | Keep the unknown text unresolved and block completion. |
| An arbitrary reason may be treated as nonexecuting text. | Accept only the finite rationale forms listed in §6.3. |
| A relative or one-time schedule may move during Preview or Save. | Resolve it once and preserve the exact instant. |

These are safety corrections, not regressions that must be preserved.

Known existing tests and examples that encode the old behavior and must be
updated intentionally during 2.7B1/2.7B2 (not silently preserved):

- `Packages/TaskOSCore/Tests/TaskOSCoreTests/OpenWebsiteTests.swift` — expects
  bare `apple.com` to normalize to `https://apple.com`.
- `Packages/TaskOSCore/Tests/TaskOSCoreTests/SuggestionEngineTests.swift` —
  expects an "Open https://apple.com" website suggestion.
- `Packages/TaskOSCore/Sources/TaskOSCore/CommandParser.swift` — the `closes`
  lifecycle alias.
- `Packages/TaskOSCore/Sources/TaskOSCore/CapabilityGuide.swift` — the
  `Open apple.com` discovery example.

---

## 3. Verified starting point

### 3.1 Baseline evidence (2026-09-13, commit `9f6105f`)

| Check | Command | Result |
|---|---|---|
| Core tests | `swift test --package-path Packages/TaskOSCore` | 270 tests / 35 suites pass |
| App tests | `xcodebuild -project TaskOS/TaskOS.xcodeproj -scheme TaskOS -configuration Debug test -only-testing:TaskOSTests` | TEST SUCCEEDED (37 test functions / 8 files) |
| Debug build | `xcodebuild ... -configuration Debug build` | BUILD SUCCEEDED |
| Release build | `xcodebuild ... -configuration Release build` | BUILD SUCCEEDED |
| UI tests | (not rerun at entry gate) | 10 methods / 2 files on record |

The UI tests and all physical checks are exercised at 2.7D3 and Phase 3.

### 3.2 Current-state gap map (code-verified)

Where the repository stands against the contracts in §4:

**Language ownership (§4.1).** No `CommandLanguageCatalog`. Word aliases live
in three independent places: `CommandParser` (`lifecycleVerbs`,
display/volume/power phrase tables, `weekdayNames`, `durationUnits`, `timeUnits`,
`excluded`), `SuggestionEngine` (hard-coded starter phrases), and
`CanonicalPhrase` (render-only). `CapabilityRegistry` holds titles/summaries but
no matched text. The `SuggestionMatch.alias` rank is dead code; no alias is ever
produced.

**Source handling (§4.2).** `SourceSpan` stores Character offsets
(`SourceSpan.swift:3-27`; `String.substring(in:)` uses `count` and
`index(offsetBy:)`). The tokenizer works on `Array(input)` of Characters
(`CommandParser.swift:22`). There is no UTF-16 conversion anywhere in the
language layer. There is no shared quoted-literal scanner and no escape
handling; `parseCopy` takes the raw remainder and strips one quote pair. There
is no full source-coverage accounting: clause spans are not required to cover
the text, and connectors/whitespace are unrepresented. `CommandParser.parse`
takes a bare `String`; there is no `CommandInput`, selection, marked-text state,
source generation, or grammar locale.

**Limits (§4.3).** Present: 12 actions
(`AutomationDefinition.maximumActionCount`), 8 suggestions
(`SuggestionEngine.limit`). Absent: 2,000-character cap, 16,384 UTF-16 cap, 128
token cap, 5,000-application snapshot cap. `WorkspaceResourceCatalog` enumerates
five standard directories and dedupes by bundle identifier, with no count
limit and no cache revision.

**Structured authoring state (§4.4).** `ComposerDocument` owns text, trigger,
`elements`, parse outcome, diagnostics, and a revision; actions carry UUIDs.
Reconciliation is identity-by-type/name with a consumed set and a card-value
merge (U-fix3), but nodes are not source-linked, have no per-node revision, and
every keystroke re-parses the whole text. There is no stable mapping from nodes
to source spans, and unresolved elements carry no span or ID. Opening a saved
workflow initializes from the typed definition (`ComposerDocument.init(
definition:)`), which is the right direction; the source-authority rule in §4.4
must be made explicit and regression-tested.

**Recoverable drafts (§4.5).** `ComposerDraft` has only `id`, `name`, `text`,
`updatedAt` (`DraftRepository.swift:3-15`). `DraftRecord` has the same four
non-optional fields, with no version or structured payload
(`Platform/SwiftDataDraftRepository.swift:5-18`). Recovery re-parses text;
card-only values (browser, notification title/message, file bookmark, specific
display, one-time date) are lost.

**Time (§4.6).** `ComposerDocument.makeDefinition` and
`triggerConfiguration` default to `Date()` (`ComposerDocument.swift:436-479`).
`.relative` ("in 45 minutes"), `.once(hour:minute:)`, and `.interval` are
re-resolved on every call: `prepare()` resolves once, `save()` resolves again,
and `upcomingOccurrences`/`triggerSignature` resolve continuously. `.oneTime`
(set from the card picker) is the only stable absolute form, and it loses its
date when rendered back to text (`"Once at h:mm AM"`). `CoreClock` and
`SystemClock` exist and are already injected at runtime; the authoring path
bypasses them.

**Asynchronous validity (§4.7).** No completion, resource-selection, or
preparation keys exist. `prepare()` publishes without a generation check;
`loadApplicationsIfNeeded()` has no staleness guard; preview/approval identity
is `(AutomationID, WorkflowRevision)` only (`WorkflowPreview`,
`ApprovalRegistry`). Cursor movement has no notion separate from text change.

**Native editor (§7.2).** `CommandComposerView` uses a SwiftUI `TextField` with
a direct binding (`Presentation/CommandComposerView.swift:18-28`). There is no
`NSTextView` wrapper, no UTF-16 selection reporting, no marked-text handling,
and no Tab handler. Undo/redo is model-level snapshots routed through
`AppNavigation`; it is not integrated with the field editor's `NSUndoManager`.

**Application resolution (§7.1).** `WorkspaceResourceCatalog.installedApplications()`
scans five directories, dedupes by bundle identifier, and sorts by display name;
there is no snapshot revision, no approved alias table, and no ambiguity report.
Text and lifecycle resolution silently take the first display-name match
(`WalkingSliceViewModel.swift:1444,1476`); the view model loads applications
once per launch.

**Preparation.** `CreationPreparer.prepare` is effect-free and revision-stamped,
and `RunCoordinator` already handles admission. Both are reusable as-is; 2.7
adds validity keys around publication and edit invalidation.

### 3.3 Contract clarifications integrated from review

1. **TaskOS naming.** All active documentation uses TaskOS. The pre-phase
   documentation commit sweeps `PLAN.md`, `PROGRESS.md`, `HANDOFF.md`, and
   `AGENTS.md`. No code identifiers change.
2. **Tab behavior (§7.2).** `PLAN.md` §2.2 says "Tab retains normal focus
   navigation". WP 2.7 intentionally replaces that while the completion panel
   is visible with a suggestion explicitly selected: Tab accepts that
   suggestion. `PLAN.md` is amended in the same commit and this exception is
   recorded here.
3. **Alias ownership (§4.1).** Grammar/capability aliases belong to
   `CommandLanguageCatalog`. Application identity aliases (display name, file
   name without `.app`, approved local aliases such as `VS Code`) belong only to
   the app-owned snapshot and resolver. No alias may exist in both owners; parity
   tests enforce the boundary and that app aliases never resolve capabilities.
4. **Saved-workflow source authority (§4.4).** Saved workflows never store
   source text. Opening one for editing initializes stable authoring nodes from
   the stored typed definition and renders canonical editable source. Typed node
   values remain authoritative until the user edits the related meaning; text
   edits never reconstruct card-only values.
5. **Over-cap application snapshot (§4.3).** Above 5,000 applications,
   automatic application search and automatic app resolution are refused with
   one clear correction; the trusted picker stays available. Never truncate the
   snapshot and resolve against a partial catalog. Boundary tests at 5,000 and
   5,001 are required in 2.7C1.

---

## 4. Shared contracts and data flow

These contracts must be settled before the grammar grows.

### 4.1 Language ownership

Use the existing domain definitions as the only source of executable capability
IDs and parameter limits.

Add a narrow `CommandLanguageCatalog` for language information only.

| Information | Owner |
|---|---|
| Action IDs, trigger IDs, typed parameters, and executable limits | Existing domain and capability definitions |
| Approved aliases, canonical wording, slot labels, and discovery text | `CommandLanguageCatalog` |
| Sentence structure, precedence, composition, and ambiguity rules | Focused parser code that reads the catalog |
| Completion text | Suggestion engine that reads the catalog |
| Canonical phrases | Canonical phrase builder that reads the catalog |
| Runtime behavior, permissions, and validation | Existing adapters and preparation path |

Do not put execution closures, platform APIs, or dynamic scripting inside the
language catalog.

Remove or redirect independently maintained alias lists. An alias must not exist
only inside the parser, only inside suggestions, or only inside canonical
rendering.

Boundary rule (clarification 3): application identity aliases are owned solely
by the app snapshot (§7.1). `CommandLanguageCatalog` never contains application
names.

### 4.2 Source and parsing contracts

Add or extend these Core concepts:

| Contract | Required meaning |
|---|---|
| `CommandInput` | Source text, UTF-16 cursor or selection, marked-text state, source generation, and grammar locale |
| `CommandEdit` | Exact UTF-16 replacement range, replacement text, and resulting selection |
| `SourceSpan` | A checked UTF-16 offset and length |
| `CapabilityReference` | An existing action ID or trigger ID |
| `InterpretationEvidence` | Which source span and approved language rule produced a typed meaning |
| `ExpectedSlot` | A missing value such as app, file, time, or notification message |
| `ParseClarification` | A safe question or edit instruction for ambiguous input |
| `TextReplacement` | Exact source range and replacement text for a suggestion |
| Parsed coverage | Every source span is executing, approved nonexecuting text, punctuation, or unresolved |

Keep the four existing result classes:

- Complete
- Needs input
- Unrecognized
- Unsupported

Ambiguity is a `Needs input` result with a clarification. Do not add an
executable "best guess" result.

A complete result requires full source coverage. No unknown suffix may
disappear.

The grammar locale is fixed to English for v1; `CommandInput` carries the value
but 2.7 ships only the `en` grammar.

### 4.3 Text limits

Enforce these limits before expensive parsing or app discovery:

- Maximum 2,000 Swift characters.
- Maximum 16,384 UTF-16 code units.
- Maximum 128 parser tokens.
- Maximum 12 actions.
- Maximum 8 visible suggestions.
- Maximum 5,000 applications in one completion snapshot.

If a limit is exceeded:

- Do not crash.
- Do not partially materialize a workflow.
- Return one clear correction.
- Keep the source text available for editing.

Application-cap rule (clarification 5): above 5,000 applications, automatic
application search and automatic app resolution refuse with one clear correction
and direct the user to the trusted picker or refresh; the snapshot is never
silently truncated.

All string ranges crossing the Core and AppKit boundary must use checked UTF-16
conversion. Invalid or stale ranges must be rejected.

### 4.4 Structured authoring state

`ComposerDocument` must own two connected forms of information:

1. The user's source text.
2. Structured authoring nodes and card values.

Each action or trigger node must have:

- A stable node ID.
- Its capability kind.
- Its current source relationship.
- Text-represented parameters.
- Card-only parameters.
- Trusted resource bindings.
- A node revision.
- Its position in the ordered action list.

Notification messages, selected files, selected folders, resolved app
identities, browser choices, display choices, and exact one-time dates are
structured data. They must not be reconstructed from display phrases.

#### Node preservation rules

Apply text edits using the exact `CommandEdit`.

- A node whose source does not overlap the edit keeps its ID and structured
  values.
- An edited node may keep its ID only when its capability kind and relevant
  text meaning remain the same.
- A card reorder moves the complete node. It does not rebuild the node from its
  displayed phrase.
- A new duplicate clause receives a new ID.
- Deleting a clause removes only the related node.
- Do not map repeated clauses by array position.
- Do not move a selected resource or notification message to another repeated
  clause.
- For a full replacement or paste, keep bindings only when the mapping is
  unique.
- If duplicate clauses make the mapping uncertain, clear the uncertain bindings
  and ask the user to choose them again.

#### Source authority for saved workflows (clarification 4)

Saved workflows never store command text. Opening one for editing initializes
authoring nodes from the typed definition and renders canonical editable source.
The typed node values are authoritative until the user edits the related
meaning. Text edits never reconstruct card-only values (browser, notification
title/message, file target and bookmark, specific display, exact one-time date,
interval anchor).

#### Round-trip meanings

Use separate round-trip meanings:

| Round trip | Required result |
|---|---|
| Text → parser | Preserve only the meaning represented in the text. |
| Configured document → edit and reparse → configured document | Preserve stable nodes, card-only values, trusted bindings, exact time values, and action order unless the related meaning changed. |

### 4.5 Recoverable draft format

Do not change the saved workflow schema for this work.

Extend only recoverable composer drafts.

Use an optional versioned structured payload in the draft record:

- Keep the existing name and text fields for compatibility and fallback.
- Add an optional encoded authoring snapshot.
- Put the draft schema version inside the encoded payload.
- Treat old records without this payload as version 1.
- Write new structured drafts as version 2.
- Add the new SwiftData field as optional so old stores can open through
  lightweight migration.
- If version 2 data cannot be decoded, restore the legacy text instead of
  deleting the draft.
- Record a non-sensitive recovery error. Do not log source text, paths, or
  notification messages.

Version 2 must preserve:

- Source text.
- Stable authoring nodes and order.
- Card-only values.
- Trusted file and folder bindings.
- Resolved application identity.
- Exact one-time schedule values.
- Authoring revision information needed for safe recovery.

Do not persist transient parser diagnostics, completion candidates, approval
tokens, or preview objects.

An old version 1 draft cannot recover card-only values because they were never
stored. Restore its Unicode text and leave missing cards unresolved.

Remove the draft after Save, New, or explicit Discard. Keep it after an app
crash or normal app termination.

Show this privacy text in the draft recovery area:

> Unsaved drafts stay on this Mac. They can include command text, selected
> files, app choices, and card text. TaskOS removes the draft after Save, New,
> or Discard.

Saved workflows, run history, and export data must remain typed and must not
gain this draft payload.

### 4.6 Time contract

The parser must not call the current clock.

It may produce:

- A relative duration.
- A local wall-clock request.
- A typed recurring schedule.
- An exact absolute date expression.

When a one-time schedule first becomes complete:

1. The app supplies the current value from the existing `CoreClock`.
2. The app supplies an explicit Gregorian calendar with the current system
   timezone.
3. The authoring layer resolves one absolute `Date`.
4. The resolved `Date` is stored in the trigger node.
5. Preview and Save reuse the stored `Date`.

Remove default `Date()` calls from definition materialization.

Do not resolve the same relative or one-time expression again during:

- Preview.
- Save.
- An unrelated text edit.
- A card edit.
- A workflow name edit.
- Cursor movement.
- Approval publication.

Only an explicit schedule edit may calculate a new instant.

If the resolved instant passes before Save, block Save and Test. Ask the user to
correct the schedule. Never move it to a later time automatically.

When the system timezone changes while the editor is open:

- Keep the exact stored instant if the schedule was not edited.
- Update its displayed local time.
- Use the new timezone only after an explicit schedule edit.

Existing saved workflows may contain seconds or either occurrence of a repeated
local time. Opening and editing an unrelated field must preserve the exact
stored `Date`.

For a new repeated local time, keep TaskOS's existing first-occurrence policy.
Show the resolved date and timezone in Preview.

### 4.7 Separate asynchronous validity keys

Do not use one request identity for all asynchronous work.

| Key | Required fields |
|---|---|
| Completion key | Session ID, source generation, UTF-16 cursor or selection, marked-text state, language revision, and app snapshot revision |
| Resource selection key | Session ID, target node ID, slot ID, node revision, and app snapshot revision when selecting an app |
| Preparation key | Session ID and authoring revision |

The authoring revision must change after every change that can alter Preview or
execution. This includes:

- Command text.
- Action or trigger order.
- Notification title or message.
- Selected file or folder.
- Selected app.
- Browser or display choice.
- Schedule card value.
- Workflow name when it appears in Preview.

Cursor movement alone must not change the authoring revision.

Every command edit and card-only change must synchronously remove the previous
Preview, Save, Test, and approval eligibility.

Cancellation is required, but cancellation is not enough. Recheck the correct
key before publishing any result.

Recheck a completion key again when the user accepts a suggestion. Apply the
replacement only to the source generation for which it was produced.

---

## 5. Phase 2.7A — Source handling, language contracts, and authoring-state preservation

**Goal:** Build the safe foundation before adding more grammar. Fix shared
vocabulary, UTF-16 ranges, stable authoring nodes, structured draft recovery,
and exact one-time values.

Do not start Phase 2.7B until the 2.7A exit gate passes.

### 5.1 2.7A1 — Freeze the language contract

**Build**

- Add work package 2.7 to the project plan and progress ledger. (Completed by
  this document's registration commit.)
- Create a reviewed capability-language matrix for every existing action and
  trigger.
- Add `CommandLanguageCatalog`.
- Make the parser, suggestions, and canonical phrase builder consume the
  catalog.
- Keep execution capability definitions in the existing registry and domain
  types.
- Record the compatibility exception table from §2.
- Correct the stale project handoff status. (Completed by this document's
  registration commit.)

**Why**

The project currently keeps language words in several places. These lists can
disagree. A shared language catalog prevents a command from being accepted in
one place and missing in another.

**Verified starting point**

Alias sources: `CommandParser` tables, `SuggestionEngine` starters,
`CanonicalPhrase` renderer, `CapabilityGuide` examples.
`SuggestionMatch.alias` exists but is never produced. No catalog exists.

**Connects to**

- Existing action and trigger IDs.
- `Packages/TaskOSCore/Sources/TaskOSCore/CapabilityRegistry.swift`
- `Packages/TaskOSCore/Sources/TaskOSCore/CommandParser.swift`
- `Packages/TaskOSCore/Sources/TaskOSCore/SuggestionEngine.swift`
- `Packages/TaskOSCore/Sources/TaskOSCore/CanonicalPhrase.swift`
- New `Packages/TaskOSCore/Sources/TaskOSCore/CommandLanguageCatalog.swift`
- Related Core test files.

**Tests**

- Every executable capability ID has one language entry.
- Every catalog alias parses to the expected existing capability ID.
- Every canonical action and trigger phrase reparses.
- Suggestions use the same canonical wording.
- No catalog entry creates a new executable capability.
- No supported alias remains private to one consumer.
- No application identity alias exists in the catalog.
- Runtime adapters and permission checks do not depend on the language catalog.

**Exit gate**

- The capability-language matrix is complete.
- Catalog parity tests pass.
- Existing safe command tests still pass.
- The next coding agent can find each language alias in one approved source.

### 5.2 2.7A2 — Make source handling safe

**Build**

- Add `CommandInput` and `CommandEdit`.
- Convert `SourceSpan` to checked UTF-16 offsets.
- Add one shared scanner for quoted literals and escape sequences.
- Add full coverage accounting.
- Add input, token, action, and suggestion limits.
- Extend parse results with evidence, expected slots, and clarifications.
- Reject stale or invalid replacement ranges.

**Literal rules**

Use double quotes for literal text and quoted app names.

Inside a quoted literal:

- `\"` means a double quote.
- `\\` means a backslash.
- No other escape sequence has special meaning.
- Preserve Unicode text exactly after these two escapes are resolved.
- An unclosed quote produces `Needs input`.

Do not lowercase, trim, split, or normalize quoted content.

A URL must begin with `http://` or `https://`. It must be one complete token. If
adjacent punctuation makes its end uncertain, ask for an edit. Do not silently
remove punctuation that may belong to the URL.

**Why**

AppKit uses UTF-16 text ranges. Swift strings do not. Unsafe conversions can
crash or replace the wrong text. Full coverage also prevents an unknown suffix
from disappearing.

**Verified starting point**

All of §3.2 "Source handling" and "Limits" applies. `SourceSpan` is
Character-based; the tokenizer is Character-based; there is no coverage
accounting, scanner, or limit enforcement.

**Connects to**

- `Packages/TaskOSCore/Sources/TaskOSCore/SourceSpan.swift`
- `Packages/TaskOSCore/Sources/TaskOSCore/ParsedCommand.swift`
- `Packages/TaskOSCore/Sources/TaskOSCore/CommandParser.swift`
- New focused scanner and input contract files in `TaskOSCore`
- Core parser and suggestion tests

**Tests**

Include:

- Emoji before, inside, and after an edit.
- Combining marks.
- Non-Latin app names.
- Curly and straight apostrophes.
- Quoted commas and connectors.
- Escaped quotes and backslashes.
- Unclosed quotes.
- Empty quotes.
- Invalid UTF-16 boundaries.
- A stale replacement range.
- Text at every size limit.
- Text one unit over every limit.
- An unknown prefix, middle span, and suffix.
- A valid command followed by unsupported text.
- A supported action followed by a dangerous unsupported imperative.

**Exit gate**

- No valid Unicode fixture crashes.
- All replacements affect the intended text.
- A complete parse has full source coverage.
- Over-limit input never creates a partial definition.

### 5.3 2.7A3 — Preserve authoring state and exact time

**Build**

- Replace position-based action reuse with stable authoring nodes.
- Apply changes through exact edit ranges.
- Preserve or clear bindings by the node rules in §4.4.
- Make card-only changes increase the authoring revision.
- Invalidate Preview and approval immediately after any meaning change.
- Add the version 2 recoverable draft payload.
- Add safe version 1 draft fallback.
- Resolve relative and one-time schedules once through the existing clock and an
  explicit calendar.
- Preserve the exact `Date` through Preview, Save, draft recovery, and unrelated
  edits.
- Preserve exact saved one-time values when an existing workflow is opened for
  editing.

**Why**

Two identical command clauses can contain different private card values. Text
alone cannot reconstruct these values. Position-based reuse can attach the wrong
message or file to the wrong action.

The current time path can also resolve the same request more than once. That can
silently move a one-time schedule.

**Verified starting point**

UUID actions and type/name reconciliation exist (U-fix3), but there are no
source-linked nodes, no node revisions, and no structured draft payload.
`makeDefinition`/`triggerConfiguration` default to `Date()`
(`ComposerDocument.swift:436-479`); `.relative`, `.once(hour:minute:)`, and
`.interval` re-resolve on each call. Opening a saved workflow already
initializes from the typed definition; keep and formalize that rule
(§4.4, clarification 4).

**Connects to**

- `Packages/TaskOSCore/Sources/TaskOSCore/ComposerDocument.swift`
- `Packages/TaskOSCore/Sources/TaskOSCore/DraftRepository.swift`
- `TaskOS/TaskOS/WalkingSliceViewModel.swift`
- `TaskOS/TaskOS/Platform/SwiftDataDraftRepository.swift`
- `TaskOS/TaskOS/AppComposition.swift`
- Core and app draft tests

**Required regression journeys**

1. Create two identical notification clauses.
2. Give each notification a different message.
3. Edit unrelated command text.
4. Reorder the notification cards.
5. Delete one clause.
6. Undo the deletion.
7. Autosave the draft.
8. Close and restore the composer.
9. Confirm that every message remains on its original node.

Repeat the same shape with two selected-file actions that use different files.

Also test:

- Inserting a third identical clause gives it a new ID.
- A full paste with uncertain duplicate mapping clears only uncertain bindings.
- A card-only change invalidates Preview and approval even when command text
  does not change.
- Cursor movement does not invalidate Preview.
- A version 1 Unicode draft restores its text and asks again for card values.
- A version 2 draft restores card values and trusted resources.
- Broken version 2 data falls back to version 1 text.
- Save, New, and Discard clear the recovery draft.
- A 45-minute schedule does not move while the user edits.
- Preview and Save use the same exact date.
- A past-due resolved date blocks Save.
- An existing saved date with seconds is unchanged after an unrelated edit.
- A repeated local time keeps its stored occurrence.
- A timezone change updates display but not the stored instant.
- An explicit schedule edit uses the new current timezone.
- Opening a saved workflow for editing authorizes typed node values over
  generated source until the related meaning is edited.

**Exit gate**

Do not start Phase 2.7B until:

- Duplicate clauses cannot exchange hidden values.
- Structured draft recovery works.
- Legacy drafts restore safely.
- Card-only changes invalidate old preparation.
- One-time dates no longer move without an explicit schedule edit.
- The saved workflow schema remains unchanged.
- Focused Core and app tests pass.

---

## 6. Phase 2.7B — Exact grammar, composition, and bounded friendly wording

**Goal:** Add exact natural-language forms for existing capabilities. Keep every
rule finite, visible, and testable.

Only start after the 2.7A exit gate passes.

### 6.1 2.7B1 — Exact action language

**Supported action families**

Only support the existing families:

- Open, launch, or start an application.
- Hide an application.
- Quit an application.
- Open an absolute HTTP or HTTPS URL.
- Open a selected file.
- Open a selected folder. (Same capability as Open File; a folder is a file
  target of folder kind.)
- Reveal a selected file or folder.
- Arrange an application using an existing window preset.
- Wait for an existing supported duration.
- Show a notification.
- Copy quoted text.

Examples may use names such as Notes or Safari, but the parser must not scan
installed applications.

**Rules**

- Application names may be quoted.
- File and folder actions use a trusted picker. The command text does not
  contain an executable path.
- Notification title and message remain card values.
- Browser choice, display choice, exact file or folder, and exact app identity
  remain structured values.
- Copy Text requires a quoted literal.
- A bare domain is not an executable URL.
- A bare domain may produce an explicit replacement suggestion such as
  `https://example.com`.
- TaskOS reparses the accepted replacement before it becomes complete.
- Command-changing negation blocks completion.
- Excluded or unsupported actions must not create a partial workflow.

**Tests**

- Every approved alias.
- Every canonical phrase.
- Quoted application names containing `and`.
- URLs with paths, query strings, and fragments.
- Bare-domain suggestion acceptance and rejection.
- Unquoted Copy Text.
- Quoted text containing `then`, commas, and semicolons.
- Unsupported destructive actions after a valid action.
- Negated actions.
- Missing app, URL, file, folder, preset, duration, or notification values.

**Exit gate**

- Every supported action produces the expected existing typed action.
- No excluded action becomes executable.
- Literal payloads are unchanged.
- Bare domains require explicit acceptance.

### 6.2 2.7B2 — Composition and schedules

**Action connectors**

Support these connectors outside quotes:

- `then`
- `and then`
- `and`
- `also`
- comma
- semicolon
- `after that`
- `next`
- `followed by`

Do not treat these words as connectors inside quoted literals or quoted app
names.

Allow app lists only for:

- Open.
- Hide.
- Quit.

Repeated action heads always create explicit boundaries.

Examples:

- `Open Notes, then open Safari`
- `Open Notes and Safari`
- `Open "Research and Notes", then open Safari`
- `Open Research, then open Notes, then open Safari`

The parser may produce unresolved list segments. Trusted app grouping happens in
Phase 2.7C1.

**Trigger rules**

- Allow zero or one trigger.
- Allow the trigger at the start or end.
- Reject a trigger in the middle.
- Reject two or more triggers.
- Do not let the last trigger silently win.
- Keep all existing supported event trigger families.
- Remove `closes` as an alias for app quit.
- Use the clear word `quits`.

**Schedule forms**

Support:

- Every day at a time.
- Weekdays at a time.
- A selected weekday set at a time.
- Weekends at a time.
- Every supported interval.
- In a supported duration.
- Once at a time.
- `Once on YYYY-MM-DD at HH:mm`.

**Time rules**

- In general input, hours 1 through 12 require AM or PM.
- Hours 00 and 13 through 23 may omit a daypart.
- `08:30` and `09:00` without AM or PM are ambiguous outside the absolute form.
- The absolute `Once on` form always uses two-digit 24-hour time from `00:00`
  through `23:59`.
- Reject impossible dates and times.
- Use the exact time contract from §4.6.

**Tests**

- Each connector between each compatible action family.
- Connectors inside literals.
- Twelve actions.
- Thirteen actions.
- Trigger first.
- Trigger last.
- Trigger in the middle.
- Two triggers.
- Event trigger aliases.
- Rejection of `closes`.
- Every schedule form.
- Leap day.
- Invalid calendar dates.
- `9 PM`, `9:00 PM`, `21:00`, ambiguous `09:00`, and absolute `09:00`.
- Timezone and repeated-time fixtures.
- Canonical phrase reparse for every schedule.

**Exit gate**

- Action order is exact.
- No text is dropped.
- One trigger is the maximum.
- Time syntax is consistent.
- Exact one-time dates remain preserved after composition.

### 6.3 2.7B3 — Friendly frames and finite rationale

**Leading frames**

Allow only these optional leading forms:

- `Hey TaskOS,`
- `TaskOS,`
- `please`
- `can you`
- `could you`
- `would you`
- `I would like you to`
- `I'd like you to`
- `I’d like you to`
- `make sure`

Allow `um,` or `uh,` only directly after the TaskOS address or immediately
before the command body. Do not remove these words from a literal or application
name.

Allow one final `.`, `?`, or `!` outside a literal.

`Make sure` is only a friendly frame. It does not create monitoring, conditions,
or a new trigger.

The approved journaling sentence must work:

> Hey TaskOS, can you make sure at 9:00 PM every day you open Notes, so that I
> can journal my day as I keep forgetting?

For this one friendly frame, allow the exact schedule order `at TIME every day`,
followed by optional `you`, followed by one supported action. Convert it to the
same typed meaning as the canonical schedule form.

**Rationale policy**

Do not accept arbitrary text after `so I can` or `so that I can`.

For work package 2.7, accept only these complete rationale endings:

- `so I can journal my day`
- `so that I can journal my day`
- `so I can journal my day as I keep forgetting`
- `so that I can journal my day as I keep forgetting`

Matching is case-insensitive outside literals. The optional final punctuation
comes after the complete rationale.

All other rationale text remains unresolved and blocks completion.

Do not decide that a suffix is safe only because it lacks a known TaskOS action
verb.

Do not add a "mark this as explanation" control in 2.7.

**Storage rule**

- Show accepted rationale text in the current composer session.
- The recoverable draft source may contain it.
- Do not copy it into the typed saved workflow.
- Do not copy it into run history or export data.

**Tests**

Positive tests:

- The full journaling sentence.
- Every listed frame.
- Every listed rationale form.
- The canonical equivalent of the journaling sentence.
- The friendly and canonical forms produce the same typed definition.

Negative tests:

- `Open Notes so I can write, then erase Downloads.`
- `Open Notes so I can write, except on weekends.`
- A suffix containing a negation.
- A suffix containing another schedule.
- A suffix containing a condition.
- A suffix containing an unsupported imperative.
- A new rationale sentence not in the four-form list.
- A rationale marker inside quoted Copy Text.

**Exit gate**

- The journaling example works.
- Its canonical form produces the same typed definition.
- Only the four listed rationale endings are nonexecuting.
- Every other unmatched suffix blocks completion.

---

## 7. Phase 2.7C — Trusted resolution, native completion, and asynchronous validity

**Goal:** Resolve applications outside the parser. Add a native command editor.
Make every asynchronous result safe against later edits.

Only start after the 2.7B exit gate passes.

### 7.1 2.7C1 — Versioned application snapshots and list ambiguity

**Build**

Create an app-owned application catalog service.

It must publish immutable, sendable snapshots containing:

- A monotonically increasing revision.
- The known applications.
- Display name.
- File name.
- Bundle identifier when present.
- Trusted application URL.
- Approved local aliases.
- Snapshot creation time.

Keep application discovery outside `CommandParser`.

Scan only approved local application locations already used by TaskOS. Do not add
network discovery.

Build a snapshot:

- When the composer opens.
- When the user asks to refresh.
- After an exact app resolution miss, if no refresh is already running.
- When TaskOS becomes active after at least 60 seconds since the last snapshot.

Coalesce concurrent refresh work. Do not publish an older snapshot after a
newer one.

**Exact app resolution**

Use exact normalized matching against the frozen snapshot.

Allow:

- Display name.
- Application file name without `.app`.
- Explicit approved aliases such as `VS Code` for Visual Studio Code.

Do not use fuzzy matching for automatic resolution.

If more than one trusted app has the same accepted name, report ambiguity. Never
select the first item.

**List grouping**

Quoted names are indivisible.

Repeated action heads force boundaries.

For connector-separated app lists:

1. Use bounded dynamic programming or bounded backtracking over the frozen
   snapshot.
2. Respect the 12-action and 128-token limits.
3. Stop after finding two distinct complete valid groupings.
4. If no grouping exists, report missing or unresolved apps.
5. If one grouping exists, use it.
6. If two or more groupings exist, ask for clarification.

Example ambiguous catalog:

- Research
- Notes
- Research and Notes
- Safari

Example ambiguous command:

- `Open Research and Notes and Safari`

Offer clear rewrites:

- `Open "Research and Notes", then open Safari`
- `Open Research, then open Notes, then open Safari`

A syntax-complete list cannot create a definition until this trusted grouping
step finishes.

**Snapshot cap (clarification 5)**

Above 5,000 applications, refuse automatic search/resolution with one clear
correction and keep the trusted picker available. Never truncate silently.

**Verified starting point**

`WorkspaceResourceCatalog.installedApplications()` scans five directories and
dedupes by bundle identifier; no revision, no aliases, no ambiguity. Text and
lifecycle lookups take the first display-name match
(`WalkingSliceViewModel.swift:1444,1476`). The view model loads once per launch.

**Connects to**

- `TaskOS/TaskOS/Platform/WorkspaceResourceCatalog.swift`
- `TaskOS/TaskOS/AppComposition.swift`
- `TaskOS/TaskOS/WalkingSliceViewModel.swift`
- New application snapshot and resolver files
- App resource-resolution tests

**Tests**

- Empty catalog.
- One exact match.
- Display-name and file-name match.
- Approved alias.
- Two apps with one display name.
- Quoted connector-bearing app name.
- Whole-list collision.
- Partial-span collision.
- More than two possible groupings.
- Snapshot refresh completing out of order.
- Resolution miss followed by refresh.
- 5,000 synthetic apps.
- 5,001 synthetic apps refuse automatic resolution.
- No parser access to AppKit or the filesystem.

**Exit gate**

- No app is selected by list order.
- Partial-name collisions are detected.
- Every resolved app comes from one versioned trusted snapshot.
- Preview, Save, and Test remain blocked while app resolution is missing or
  ambiguous.

### 7.2 2.7C2 — Native command editor and completion

**Build**

Wrap `NSTextView` through SwiftUI.

The editor must report:

- Current text.
- UTF-16 selection.
- Exact edit range and replacement text.
- Marked-text state.
- Cursor movement.
- Undo and redo changes.

Show a completion panel connected to `SuggestionEngine`.

Immediate grammar suggestions may run synchronously. Application and typo
searches run asynchronously.

A suggestion must contain:

- Display text.
- Meaning.
- Exact `TextReplacement`.
- The completion key for which it was produced.
- Whether it is exact, grammatical, resource-based, or a typo proposal.

**Keyboard behavior**

When no marked text exists and the panel is visible:

- Up and Down move through suggestions.
- Return accepts the selected suggestion.
- Tab accepts only when the suggestion is explicitly selected.
- Escape closes the panel.
- Normal typing continues to edit the text.

Return must not trigger Save or Test.

Tab behavior is the intentional WP 2.7 replacement for the `PLAN.md` §2.2 bullet
"Tab retains normal focus navigation" (clarification 2). Outside the visible
panel with a selected suggestion, Tab keeps normal focus navigation.

Add VoiceOver labels for:

- Suggestion count.
- Selected suggestion.
- Replacement meaning.
- Ambiguity and missing-value messages.

**Marked-text rule**

While marked text exists:

- Hide or suspend the TaskOS completion panel.
- Reject completion acceptance.
- Do not intercept Return, Tab, Escape, or arrow keys for TaskOS.
- Do not prepare a workflow.
- Do not start application or typo searches.
- Let the macOS input method handle composition.

After composition commits:

- Read fresh text and selection.
- Start a new source generation.
- Reparse.
- Resume completion from the new state.

**Verified starting point**

`CommandComposerView` is a SwiftUI `TextField` with a direct binding
(`Presentation/CommandComposerView.swift:18-28`). No `NSTextView` wrapper, no
marked-text handling, no UTF-16 selection, and no Tab handler exist. Undo/redo is
model-level via `AppNavigation` and is not integrated with the field editor's
undo manager.

**Connects to**

- `TaskOS/TaskOS/Presentation/CommandComposerView.swift`
- `TaskOS/TaskOS/WalkingSliceViewModel.swift`
- New native command editor and completion panel files
- `SuggestionEngine` and suggestion types
- App UI tests

**Tests**

- Cursor replacement at the start, middle, and end.
- Replacement next to emoji and combining marks.
- Selection replacement.
- Undo and redo.
- Paste of a multi-action command.
- Escape, Tab, Return, and arrows.
- Return with no suggestion selected.
- VoiceOver labels and reading order.
- Suggestion visible, then marked text begins, then Return is pressed.
- The input method receives Return.
- TaskOS does not accept a suggestion, Save, or Test.
- Completion resumes only after the composition commits.

**Exit gate**

- Text editing remains native and undoable.
- UTF-16 selections remain correct.
- Completion does not interfere with input methods.
- Completion acceptance uses an exact checked replacement.

### 7.3 2.7C3 — Result validity and bounded typo help

**Build**

Use the three validity keys from §4.7.

For completion:

- Cancel old work.
- Recheck the completion key before publication.
- Recheck it again before acceptance.
- Reject an old replacement range.

For resource selection:

- Confirm the current session.
- Confirm the target node and slot.
- Confirm the node revision.
- Confirm the resource is still valid.
- Confirm the app snapshot revision for app selection.

For preparation:

- Capture the preparation key.
- Cancel earlier preparation.
- Publish Preview or approval only when the authoring revision still matches.
- Never use cursor position as the only preparation identity.

**Typo proposals**

Typo matching may offer an edit. It must never select an app automatically.

Use these bounds:

- Fewer than 5 query characters: no typo proposals.
- 5 through 8 characters: maximum edit distance 1.
- 9 through 64 characters: maximum edit distance 2 and normalized distance at
  most 0.20.
- More than 64 characters: no typo proposals.
- Search no more than 5,000 applications.
- Show no more than 3 typo proposals.
- Keep all proposals within the total 8-suggestion limit.
- Reparse and resolve after the user accepts one.

**Verified starting point**

No validity keys exist. `prepare()` publishes without a generation check;
`loadApplicationsIfNeeded()` has no staleness guard; preview/approval identity
is `(AutomationID, WorkflowRevision)` only. `SuggestionEngine` typo help is
synchronous and unbounded by query length.

**Tests**

Use controllable delayed tasks.

- Old completion finishes after new completion.
- Old completion is canceled but still returns.
- A suggestion appears, the user edits, and then clicks the old suggestion.
- Cursor moves without changing the authoring revision.
- A notification message changes while preparation runs.
- A resource picker returns after its target node is deleted.
- An app snapshot changes while app resolution runs.
- Two preparation requests finish out of order.
- A stale task tries to publish approval.
- Typo proposal thresholds at every boundary.
- Typo acceptance followed by a new exact parse and trusted resolution.

**Exit gate**

Do not start Phase 2.7D until:

- Stale completion cannot publish or apply.
- Stale resource selection cannot bind.
- Stale preparation cannot publish Preview or approval.
- Cursor-only movement does not invalidate an unchanged Preview.
- Card-only changes always invalidate old preparation.
- Typo help is explicit and bounded.
- Full Core and app test suites pass.

---

## 8. Phase 2.7D — Independent end-to-end qualification

**Goal:** Prove that the full feature is safe, compatible, usable, and fast
enough.

### 8.1 2.7D1 — Independent language corpus

Create a reviewed test corpus that does not generate expected results from
production parser code or the production language catalog.

Include:

- Every supported action.
- Every supported trigger.
- Every approved alias.
- Every canonical phrase.
- Every schedule form.
- Every connector.
- Quoted literals.
- Unicode.
- Friendly frames.
- The four rationale forms.
- App-list collisions.
- Missing resource cases.
- Unsupported and dangerous tails.
- Compatibility exceptions.
- Limit boundaries.

Generate at least:

- 2,000 positive commands from reviewed test fixtures.
- 100 held-out negative commands.
- Dedicated ambiguity fixtures with exact expected clarifications.

Use a fixed seed for generated cases.

**Acceptance**

- Every positive command produces the exact expected typed meaning or expected
  unresolved slot.
- Every ambiguity produces `Needs input`.
- Every negative command fails closed.
- There are zero silent wrong complete results.
- There are zero dropped source spans.
- Friendly and canonical forms produce equal typed definitions.
- The oracle does not import or derive expected values from production parser
  rules.

### 8.2 2.7D2 — Integration, persistence, and privacy

Run end-to-end tests through:

> Command input → composer → app and resource resolution → typed definition →
> preparation → Preview → approval → Test or Save

Also prove:

- Saved workflows run when the parser is not constructed.
- Existing saved workflow fixtures still decode.
- Exact existing one-time dates survive unrelated edits.
- Version 1 drafts restore text safely.
- Version 2 drafts restore structured authoring state.
- Saved workflow records contain no source text.
- Run history contains no source text.
- Exports contain no source text.
- Accepted rationale is absent from saved workflows, history, and exports.
- Recoverable draft data is removed after Save, New, and Discard.
- Logs and test failure messages do not print private command text, notification
  messages, paths, or bookmarks.
- Preview remains effect-free.
- Test and Save remain explicit user actions.
- Existing validation, permissions, approval, and runner paths remain in use.

Inspect serialized fixtures directly. Do not rely only on UI observations.

### 8.3 2.7D3 — Performance and physical proof

**Measurement protocol**

Record:

- Mac model.
- CPU.
- RAM.
- macOS build.
- Xcode version.
- Swift version.
- Debug or Release configuration.
- Corpus size.
- Application snapshot size.
- Warm-up count.
- Measured sample count.
- Start and end of each timing boundary.

Use an optimized Release build for qualification.

Run:

- At least 100 warm-up parses.
- At least 10,000 measured parser runs across the qualification corpus.
- At least 100 warm-up completion runs.
- At least 1,000 measured completion runs against 5,000 synthetic applications.

Measure these separately:

- Core parse computation.
- Application search computation.
- End-to-end completion time from editor change callback to published
  suggestion model.

Targets:

- Parser p95 at or below 10 milliseconds.
- Parser p99 at or below 25 milliseconds.
- End-to-end completion p95 at or below 100 milliseconds during normal typing.

These are targets until measured. Do not write them as achieved results before
evidence exists.

Record cold application snapshot time separately. Do not invent a pass target
without baseline evidence.

**Automated checks**

Run:

- `swift test --package-path Packages/TaskOSCore`
- App unit tests.
- Debug app build.
- Release app build.
- Existing UI tests.
- New command composer UI tests.
- `git diff --check`
- A source inspection for forbidden Core imports and forbidden AI or network
  dependencies.

**Physical Mac journeys**

Perform and record these separately from automated tests:

- Type and edit the full journaling sentence.
- Use mouse and keyboard completion.
- Reorder two identical notifications with different messages.
- Restore a structured recoverable draft.
- Accept a bare-domain HTTPS proposal.
- Resolve an ambiguous app list by quoting one app.
- Verify a relative schedule does not move during editing.
- Verify a past-due one-time schedule blocks Save.
- Use one owner-selected non-Latin macOS input method.
- Begin marked-text composition while a suggestion is visible and press Return.
- Use VoiceOver to hear suggestion count, selection, and clarification text.
- Use Notes and Safari or other harmless installed apps for Test.
- Confirm Preview has no effect.
- Confirm Test requires explicit action.
- Confirm Save requires explicit action.
- Confirm no microphone or network permission is requested.

Record automated, UI, physical, and performance evidence as different evidence
types.

**Final exit gate**

Work package 2.7 is complete only when:

- All 2.7A, 2.7B, and 2.7C gates pass.
- The independent corpus passes.
- Existing saved workflows remain compatible.
- Draft migration and recovery pass.
- Privacy inspection passes.
- Debug and Release builds pass.
- Automated and UI tests pass.
- Required physical checks are recorded.
- Performance measurements meet the targets or an owner-approved product
  decision changes those targets.
- `PROGRESS.md` names delivered behavior, interface changes, test evidence,
  physical evidence, remaining defects, and the next eligible work package.
- No 2.7 defect or required evidence gap remains open.

After completion:

- Commit each bounded sub-increment according to `AGENTS.md`.
- Create the annotated tag `wp-2.7-language` after the full work package passes.
- Ask the owner before any push.
- Start broad Phase 3 qualification only after 2.7 is closed.

---

## 9. Entry gate record

**Gate status: CLOSED for adoption on 2026-09-13.**

| Gate item | Result |
|---|---|
| Worktree and commit confirmed | `9f6105f`, working tree clean at registration |
| Core baseline | 270 tests / 35 suites pass |
| App baseline | TEST SUCCEEDED (37 test functions / 8 files) |
| Builds | Debug and Release BUILD SUCCEEDED |
| `PLAN.md`, `PROGRESS.md`, code checked | Yes; gap map in §3.2 |
| 2.7 recorded as next work package | Yes (`PLAN.md` / `PROGRESS.md`) |
| Stale `HANDOFF.md` corrected | Yes, same commit |
| Older physical checks resolved | Owner-approved deferral to Phase 3 (below) |

### 9.1 Owner-approved deferral of older physical checks (2026-09-13)

The following checks were `pending` in `PROGRESS.md`. The owner deferred all of
them to Phase 3 qualification, with the reason that work package 2.7 replaces
the composer, suggestion, source-handling, and revision layers those checks
exercised; rerunning them now would produce evidence for code 2.7 supersedes.
Work package 2.7 carries its own physical gates in §8.3, and Phase 3.1–3.3
re-covers legacy journeys on the frozen build.

Named deferred checks:

- 2.1: H2-a menu-bar run/pause/cancel re-check; H2-c live history and run
  duration re-check.
- 2.2: I1 Copy Text; I2 Hide/Quit; I3 specific display and notification review.
- 2.3: J1 selected files; J2 missing-file repair; J3 export/import.
- 2.5: M3 template/discovery physical pass.
- 2.6: N1 skipped/queue events; N2 attention/Fix/expanded history; N3 retention;
  N4 permission settings buttons and onboarding.
- Post-Phase-2: N-c filesystem watch; N-d Accessibility attention; N-e attention
  clears after grant; P1 card-only values on edit; P2 manual runs through
  admission; P3 persisted admission events; Q1 import display mapping; Q2
  website suggestion.
- UI redesign: U4 accessibility/responsive manual pass.
- UX polish: UX-1 lifecycle/library status; UX-2 blocking reason; UX-3 run-result
  honesty; UX-4 empty-state title; UX-5 default name prompt.
- D2 manual regression matrix (Phase 1 canonical journey; 2.1 A–E; 2.4 all six
  event families; 2.5 templates/discovery; 2.6 attention/permissions/retention;
  2.3 export/import; compact resize; light/dark).

No qualification gate that belongs to work package 2.7 is deferred.

### 9.2 Owner inputs required before 2.7D3

- One enabled non-Latin macOS input source for the IME test.
- Permission to use VoiceOver for the accessibility check.
- Any normal macOS notification or accessibility permission needed by existing
  TaskOS Test actions.
- A harmless set of installed apps for physical testing (Notes and Safari are
  sufficient).
- Approval before any Git push.

### 9.3 Next eligible work package

**2.7A1 — Freeze the language contract** (the capability-language matrix and
`CommandLanguageCatalog`; the plan/ledger/handoff portions of 2.7A1 are already
delivered by this registration commit).

---

## 10. Risks, dependencies, and required owner input

### 10.1 Main risks

| Risk | Required control |
|---|---|
| A hidden message or file moves to another repeated action. | Stable node IDs, exact edit ranges, and conservative binding removal when mapping is uncertain |
| Preview and Save choose different one-time dates. | Resolve once with `CoreClock` and reuse the exact `Date` |
| A saved time loses seconds or changes DST occurrence. | Keep the typed `Date`; treat display text as non-authoritative until schedule edit |
| Parser, suggestions, and canonical phrases use different aliases. | Shared language catalog and consumer parity tests |
| An app name is grouped incorrectly. | Frozen snapshot and bounded multi-group ambiguity search |
| A stale asynchronous task publishes after an edit. | Cancellation plus result-specific validity keys |
| Completion breaks an input method. | Native NSTextView marked-text rules and physical IME proof |
| Recoverable drafts contain private unsaved data. | Local-only storage, clear disclosure, no private logging, and deletion after Save, New, or Discard |
| UTF-16 range conversion crashes or edits the wrong source. | Checked conversion and Unicode boundary tests |
| Friendly language becomes an unrestricted parser fallback. | Finite frames and four exact rationale forms |
| Old unsafe behavior is treated as required compatibility. | Written compatibility exception table in §2 |
| Performance numbers are reported without proof. | Fixed measurement protocol and recorded machine details |
| A new language layer becomes a second engine. | Language-only catalog and existing runtime path |

### 10.2 External dependencies

No external API, account, credential, model, subscription, server, or cloud
service is required. No new asset is required.

The implementation depends on:

- Existing TaskOS capability definitions.
- Existing `CoreClock`.
- Existing trusted application, file, and folder target types.
- Existing preparation, approval, repository, and runner paths.
- AppKit `NSTextView` and marked-text behavior.
- Local application discovery.
- SwiftData lightweight migration for the optional draft payload.

### 10.3 The owner must provide

Before implementation: nothing further; the entry gate is closed.

Before physical qualification: the inputs listed in §9.2.

The owner does not need to provide API keys, AI provider access, a speech
service, a server, a database service, a web account, design artwork, or a
third-party plugin.

---

## 11. Future capability onboarding

This section is a checklist. It is not another phase of work package 2.7.

When TaskOS later adds a real action or trigger family, the new work package
must cover:

1. A typed domain definition.
2. A capability registry entry.
3. A platform adapter or event source.
4. Validation, safety, and permission rules.
5. Trusted resource handling.
6. Composer card controls.
7. Language catalog metadata.
8. Focused grammar and canonical wording.
9. Persistence and migration compatibility.
10. Focused unit, integration, UI, and physical tests.
11. Privacy and export checks.
12. A complete work-package gate.

Use the next genuinely useful product capability to test this onboarding path.
Do not add a dummy production capability only to demonstrate extensibility.

---

## 12. Execution conventions

- Work through the numbered sub-increments in order: 2.7A1, 2.7A2, 2.7A3,
  2.7B1, 2.7B2, 2.7B3, 2.7C1, 2.7C2, 2.7C3, 2.7D1, 2.7D2, 2.7D3.
- Do not start a phase until the previous phase's exit gate passes. Do not start
  2.7B before 2.7A passes; do not start 2.7C before 2.7B passes; do not start
  2.7D before 2.7C passes.
- Follow the `AGENTS.md` per-work-package loop: implement one complete
  behavior, run focused tests, update `PROGRESS.md`, commit locally, stop.
- Commit locally after each bounded sub-increment. Ask before every push.
- Create the annotated tag `wp-2.7-language` only after the full 2.7D final exit
  gate passes. This is the package's explicit exception to the per-sub-phase tag
  cadence in `AGENTS.md`; sub-increment commits stay as untagged local history.
- The saved workflow schema must not change. Only the recoverable draft record
  gains the optional version 2 payload.
- No comments in code unless asked.
- Record automated, UI, physical, and performance evidence as separate types;
  never report a target as achieved before evidence exists.
