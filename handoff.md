# Handoff

## Active Mode
Swift Package Manager Mode

## Current Milestone
Release v1.0.0 packaging and publication

### Phase
1. Goal  
Ship the first usable Quoteable Quotes `.saver` release:
- validate the current Swift/macOS baseline
- build the release `.saver` bundle
- create small install/wiki documentation
- prepare repo release-page content
- commit the release-ready workspace

2. Constraints  
- Keep project buildable at all times.  
- No speculative dependencies.  
- Keep release documentation concise and tied to the current bundle behavior.
- Preserve current working defaults when custom inputs are absent.

3. Files to Modify  
- `README.md`
- `ACTIVE_CONTEXT.md`
- `SaverBundle/Info.plist`
- `docs/wiki/Installation.md`
- `docs/releases/v1.0.0.md`
- `handoff.md`

4. Build/Test Command  
- `scripts/compile-options-xib.sh`
- `swift build -c release`
- `swift test`
- `scripts/build-saver.sh`

5. Success Definition  
`swift build -c release`, `swift test`, and `scripts/build-saver.sh` succeed without error.

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
- Quote library expansion refresh complete:
  - Expanded all bundled quote XML files from 50 to 100 total entries.
  - Verified 100 unique bodies in every themed `*-quotes.xml` file.
  - Rebuilt `quotes.xml` as a 100-entry mixed sample with 20 quotes from each themed library.
  - Folded Arthur Schopenhauer into `stoicism-quotes.xml`.
  - Added test coverage for bundled library counts, uniqueness, mixed sampling, and Schopenhauer inclusion.
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
- Milestone 5 slice complete: attribution display
  - Added persisted `showsAttribution` setting in `AppSettings`.
  - Added options toggle: `Show Attribution (bottom-right)`.
  - Added attribution rendering in quote view:
    - bottom-right placement
    - smaller text than quote body
    - preferred font `Arial Narrow`, fallback `Tahoma`.
  - Fullscreen input-exit monitor exits on keyboard and mouse input.
- Workspace expansion complete:
  - Added root `ACTIVE_CONTEXT.md` to distinguish Swift/macOS and HA/web work in the shared workspace.
  - Added parent `.gitignore` rule for nested `QQ-ha/` repo isolation.
  - Moved HA port planning into nested `QQ-ha/sketch.md`.
- Generic quote library registration complete:
  - Added `generic-quotes.xml` to the bundled theme lists for both standalone app and `.saver`.
  - Confirmed bundled XML resources are copied directly from `Sources/ScreenSaver/Resources` during build/package steps rather than generated from a cached quote manifest.
- Saver install-path fix complete:
  - `scripts/install-saver.sh` now removes any previously installed `~/Library/Screen Savers/QuoteableQuotes.saver` before copying the new bundle.
  - This fixes stale installs where System Settings kept loading the February 28, 2026 bundle despite fresh builds in `dist/`.
- Hotkey removal cleanup complete:
  - Removed playback hotkey code from both the standalone app and the `.saver`.
  - Removed quote-history/pause state and related tests.
  - Removed documentation that advertised hotkey support.
- Options layout refactor complete:
  - Reworked the standalone `Options...` display tab into sectioned `NSBox` groups with stack-based layout.
  - Grouped related controls together (`Appearance`, `Background`, `Quote Source`, `Playback`) and placed `Background Color` / `Font Color` on the same row for cleaner visual editing.
  - Preserved the existing settings/actions model while making the dialog structure more visually tunable.
- Visual `.xib` scaffold added:
  - Added `Sources/ScreenSaver/Resources/DisplayOptionsView.xib` as an Xcode-openable basis for visually editing the standalone options dialog layout.
  - The `.xib` validates with `ibtool` and is intentionally not wired into the live app yet, so you can reshape it in Interface Builder without destabilizing the working dialog.
  - Intended future use: finalize the standalone layout visually, then use it as the basis for the `.saver` options migration.
- Wired `.xib` control surface added:
  - Replaced the placeholder/image mockup in `Sources/ScreenSaver/Resources/DisplayOptionsView.xib` with actual AppKit controls for all current display settings.
  - Added controller-side design-time outlets in `Sources/ScreenSaver/OptionsViewController.swift` so the XIB has real connections for popups, color wells, sliders, value labels, path labels, and buttons.
  - Connected XIB controls to the existing action methods (`fontDidChange:`, `themeDidChange:`, `chooseXMLFile:`, etc.) while leaving the live standalone app on the stable programmatic dialog for now.
  - `ibtool --compile /tmp/DisplayOptionsView.nib Sources/ScreenSaver/Resources/DisplayOptionsView.xib` succeeds.
- Standalone app now prefers the XIB-backed dialog:
  - `DisplayOptionsViewController` now prefers `DisplayOptionsView.nib` from `Bundle.module` and falls back to the programmatic layout if the nib is unavailable.
  - Added `scripts/compile-options-xib.sh` to compile `DisplayOptionsView.xib` into `Sources/ScreenSaver/Resources/DisplayOptionsView.nib` for SwiftPM CLI builds.
  - `AppDelegate` now sizes the options window from the controller's preferred content size instead of the old hardcoded small rect.
  - `swift build` copies both `DisplayOptionsView.nib` and `DisplayOptionsView.xib` into the app resource bundle; runtime should pick up the nib.
- Fullscreen options-entry fix:
  - `Cmd+,` is now explicitly allowed in standalone `--fullscreen` mode without being treated as dismissal input.
  - Opening the options window temporarily disables fullscreen exit-on-input; closing the options window restores it.
  - This preserves the screensaver-like input-exit behavior while still allowing the options dialog to be reached in fullscreen.
- Nib-backed dialog sizing fix:
  - The standalone options window now uses the XIB view's actual frame size as a floor instead of relying only on `fittingSize`.
  - This prevents the nib-backed dialog from opening too short and clipping lower controls even when the visual layout itself is correct.
- Fullscreen windowing fix:
  - The standalone `--fullscreen` mode no longer relies on native `toggleFullScreen`.
  - It now opens a borderless window sized directly to `NSScreen.main.frame`, which keeps quote text and attribution coordinates aligned to the actual display bounds.
  - This avoids the content offset/clipping issues seen with the previous native fullscreen transition path.
- Fullscreen visibility fix:
  - The borderless fullscreen window now uses `.moveToActiveSpace`, `orderFrontRegardless()`, and an elevated window level so it actually appears above the launch surface/current desktop.
  - The standalone options window is raised to `.modalPanel` while fullscreen is active so it still appears above the quote wall.
- Fullscreen host-window adjustment:
  - Replaced the fully borderless standalone fullscreen window with a keyable titled window using `.fullSizeContentView`, hidden title chrome, and screen-sized framing.
  - Activation now uses `NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])` so fullscreen launch should take focus without needing `Cmd+Tab`.
- Fullscreen activation and options-close exit fix:
  - Fullscreen launch now gets a second deferred activation/order-front pass to improve focus acquisition at app startup.
  - Closing the options window no longer immediately re-arms exit-on-input on the same mouse/key gesture; the re-enable is delayed slightly so the close interaction itself does not terminate the app.
- Fullscreen path simplified again:
  - The standalone app is back on the native `toggleFullScreen` path instead of the borderless/keyable host-window experiments.
  - `QuoteViewController.loadView()` no longer disables autoresizing-mask translation on the top-level root view, which was a plausible cause of the previous fullscreen content offset.
- Saver options sheet now uses the shared XIB-backed layout:
  - `QuoteableQuotesView` can now load `DisplayOptionsView.nib` from the saver bundle and bind the same controls used by the standalone app.
  - The saver maps the loaded XIB controls onto its existing settings properties and uses selector aliases so the existing saver persistence/actions continue to work.
  - The hand-built saver options form remains as a fallback if the nib cannot be loaded.
  - `scripts/build-saver.sh` succeeds with the shared nib copied into the `.saver` bundle resources.
- XML font suggestion precedence is now active:
  - Standalone rendering now uses a quote's XML `font` value when present and falls back to the font selected in `Options...` otherwise.
  - The `.saver` parser now reads `<font>` from XML and applies the same precedence rule at render time.
  - Added test coverage for the standalone precedence helper and validated both `swift test` and `scripts/build-saver.sh`.
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
- Release v1.0.0 prep:
  - Switched active context back to the root Swift/macOS project.
  - Added install wiki content at `docs/wiki/Installation.md`.
  - Added repo release-page draft at `docs/releases/v1.0.0.md`.
  - Set saver bundle short version to `1.0.0`.

## Build Status
- Last successful XIB compile command: `scripts/compile-options-xib.sh`
- Last successful build command: `swift build -c release`
- Last successful test command: `swift test`
- Last successful saver build command: `scripts/build-saver.sh`

## Outstanding Blockers
- No code blockers for current baseline.
- GitHub release/wiki publication still depends on local git commit and remote/auth availability.
