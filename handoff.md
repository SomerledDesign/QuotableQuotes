# Handoff

## Active Mode
Swift Package Manager Mode

## Current Milestone
Milestone 7: hotkey re-introduction and stability

### Phase
1. Goal  
Re-introduce quote playback hotkeys with stable behavior in standalone and `.saver` runtimes.

2. Constraints  
- Keep project buildable at all times.  
- No speculative dependencies.  
- Implement in small slices (input handling, playback state model, tests).  
- Preserve current working defaults when custom inputs are absent.

3. Files to Modify  
- `Sources/ScreenSaver/QuoteViewController.swift`  
- `Sources/ScreenSaver/AppSettings.swift`  
- `SaverBundle/*`  
- `Tests/ScreenSaverTests/ScreenSaverTests.swift`  
- `README.md`
- `sketch.md`

4. Build/Test Command  
- `swift build -c release`  
- `swift test`

5. Success Definition  
`swift build` succeeds without error.

## Completed Work
- Bootstrapped Swift package project (`ScreenSaver` executable target).  
- Implemented AppKit fullscreen/borderless black window setup.  
- Implemented quote presentation with Papyrus white text and author line.  
- Added 5-second timer-driven quote rotation with fade transition.  
- Added hardcoded Milestone 1 quote set (4 quotes).  
- Added unit tests for quote deck cycling and quote count.
- Documented one-command run flow via `swift run ScreenSaver` in `README.md`.
- Added launch diagnostics in `main.swift` and `AppDelegate.swift`.
- Switched default `swift run ScreenSaver` behavior to a visible debug window.
- Added fullscreen mode flag: `swift run ScreenSaver --fullscreen`.
- Updated fullscreen window behavior to open on active space with explicit frame logs and front-most ordering.
- Added fullscreen input monitor so mouse/keyboard input exits immediately (screensaver-like behavior).
- Added persisted style settings store (`AppSettings`) for font and background color.
- Extended persisted style settings with foreground text color and font size.
- Added `Options...` menu action (`Cmd+,`) and options window.
- Added tabbed options controller with a `Display` tab.
- Added font family dropdown and background color picker controls.
- Added font color picker and font size slider controls.
- Wired options changes to live-update quote view style.
- Milestone 2 features are now in place and usable in the app options window.
- Milestone 3 Step 1 complete:
  - Added XML quote parser (`QuoteXMLParser`).
  - Added bundled default quotes file (`Sources/ScreenSaver/Resources/quotes.xml`).
  - Switched quote initialization to XML-first with hardcoded fallback.
  - Added parser test coverage.
- Milestone 3 Step 2 complete:
  - Added options UI controls for quote XML source selection (`Choose XML...`, `Use Bundled`).
  - Added persisted custom quote file path in `AppSettings`.
  - Added quote-source change notification and live deck reload in `QuoteViewController`.
  - Added test coverage for valid custom XML path loading.
- Side quest complete:
  - Extended XML schema support with optional `theme` and `font` keys per quote entry.
  - Added themed quote libraries with minimum 50 quotes each:
    - `leadership-quotes.xml`
    - `stoicism-quotes.xml`
    - `comedic-quotes.xml`
    - `greek-philosophers-quotes.xml`
    - `french-revolutionaries-quotes.xml`
  - Refreshed default `quotes.xml` to keyed format and 50-entry mixed set.
  - Updated parser tests to validate keyed XML entries.
- Added theme selection UX for bundled quote libraries:
  - Persisted bundled quote file selection in `AppSettings`.
  - Added `Theme` dropdown to Options to switch bundled XML files.
  - Theme selection clears custom file override and reloads quotes live.
  - Added test coverage for bundled file selection behavior.
- Added `attribution` key support across quote model/parser and bundled XML files.
- Curation pass (high-accuracy staged) started:
  - Replaced placeholder content in `stoicism-quotes.xml` and `greek-philosophers-quotes.xml` with internet-sourced quote sets including source/work metadata and URLs in `attribution`.
  - Kept 50-entry file size by cycling curated sets per theme.
- Curation pass extended to remaining themes:
  - Replaced placeholder content in `leadership-quotes.xml`, `comedic-quotes.xml`, and `french-revolutionaries-quotes.xml`.
  - Added internet-sourced attribution metadata in format `Work/Context (Year) | URL`.
  - Preserved 50-entry file size per theme by cycling curated sets.
- Uniqueness pass in progress:
  - Increased all themed quote files from 15 unique bodies to 25 unique bodies each (still 50 total entries per file).
  - Increased all themed quote files from 25 unique bodies to 35 unique bodies each (still 50 total entries per file).
  - Completed final pass: all themed quote files now have 50 unique bodies / 50 total entries.
- Mixed/default quote source refresh complete:
  - Rebuilt `quotes.xml` as a true mix with 10 quotes from each bundled theme file (50 total).
  - Added per-theme metadata on each mixed quote entry (`theme`, `font`, `attribution`).
- Hardcoded fallback refresh complete:
  - Replaced generic fallback set with 10 themed quotes (2 from each theme).
- Random no-repeat rotation complete:
  - Updated `QuoteDeck` to shuffle quote indices and show each quote exactly once per cycle before reshuffling.
  - Added/updated test coverage to validate uniqueness per cycle and new fallback composition.
- Documentation sync complete:
  - Updated `sketch.md` Milestone 3 content to reflect implemented XML schema, themed bundles, true mixed default source, fallback policy, and random no-repeat behavior.
  - Updated `README.md` to match implemented settings/options, XML structure, bundled libraries, and runtime quote behavior.
- Milestone 4 slice complete: dynamic quote timing
  - Added quote word-count parsing and recommended display duration calculation in `Quote`.
  - Replaced fixed repeating 5-second timer with per-quote scheduling in `QuoteViewController`.
  - Quote duration now scales from 5s at ~7 words, reaches 8s at ~13 words, and caps at 15s for very long quotes.
  - Added test coverage for duration scaling and cap behavior.
- Milestone 4 slice complete: animation styles
  - Added persisted `AnimationStyle` setting in `AppSettings`.
  - Added `Animation Style` dropdown to options UI.
  - Implemented transition styles in `QuoteViewController`:
    - Fade
    - Drop down from top
    - Slide in from left/right
    - Materialize in center
    - Genie from corner
    - Transparent + flag-wave entrance
  - Added test coverage that validates all animation modes are exposed.
- Milestone 4 slice complete: random transition + manual base time
  - Added `Random Transition` animation mode and wired it to pick a new concrete transition each quote.
  - Added persisted manual `Base Quote Time (sec)` setting (3.0 to 20.0).
  - Added options slider for base quote time and live rescheduling on style settings changes.
  - Dynamic timing now uses `recommendedDisplayDuration(baseSeconds:)` from the user-selected base.
  - Added test coverage for custom-base duration calculation.
- Milestone 5 slice complete: attribution display + keyboard playback controls
  - Added persisted `showsAttribution` setting in `AppSettings`.
  - Added options toggle: `Show Attribution (bottom-right)`.
  - Added attribution rendering in quote view:
    - bottom-right placement
    - smaller text than quote body
    - preferred font `Arial Narrow`, fallback `Tahoma`.
  - Added keyboard controls in windowed and fullscreen:
    - `Left Arrow`: pause + previous quote
    - `Right Arrow`: pause + next quote
    - `Space`: pause/resume playback
  - Added quote-history navigation so previous/next works predictably while preserving randomized deck behavior for unseen quotes.
  - Fullscreen input-exit monitor now passes arrow/space controls through and still exits on `Esc`/other key input and mouse input.
- Hotkey rollback (post-Milestone 6 stabilization):
  - Removed arrow/space playback hotkey handling from both standalone app and `.saver`.
  - Removed quote pause/history keyboard plumbing tied to hotkey behavior.
  - Updated docs to move hotkeys into Milestone 7.
- Background image reliability patch:
  - Hardened bundled image lookup in standalone and `.saver` targets (normalized subdirectory/resource lookup).
  - Expanded tilde (`~`) paths for custom background image loading.
- Documentation cleanup:
  - Updated `README.md`, `sketch.md`, and `handoff.md` for current baseline and release-first workflows.
- Code documentation pass:
  - Added Doxygen-style API comments across key Swift source files.
- Milestone 6 complete: resources cleanup + `.saver` packaging
  - Updated bundled background references to `Resources/images/*` paths.
  - Updated bundled image loading logic to resolve subdirectory assets correctly.
  - Added standalone screen saver bundle source:
    - `SaverBundle/QuoteableQuotesView.swift`
    - `SaverBundle/Info.plist`
  - Added scripts to build/install the screen saver bundle:
    - `scripts/build-saver.sh`
    - `scripts/install-saver.sh`
  - `scripts/build-saver.sh` now produces `dist/QuoteableQuotes.saver`.
  - Updated README with `.saver` build/install workflow.

## Build Status
- Last successful build command: `swift build -c release`  
- Last successful test command: `swift test`

## Outstanding Blockers
- No code blockers for current baseline.
- Milestone 7 hotkey behavior remains intentionally deferred and unimplemented in the current build.
