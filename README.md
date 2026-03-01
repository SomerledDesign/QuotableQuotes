# ScreenSaver

macOS quote screensaver prototype built with Swift Package Manager.

## Prerequisites
- macOS
- Xcode command line tools (`swift` available in shell)

## Build (Release)
From repository root:

```bash
swift build -c release
```

## Run Standalone App (Release)
Windowed:

```bash
swift run -c release ScreenSaver
```

Fullscreen:

```bash
swift run -c release ScreenSaver --fullscreen
```

In fullscreen mode, mouse or keyboard input exits the app (screensaver-style behavior).

## Build `.saver` Bundle (Release)

```bash
scripts/build-saver.sh
```

Output:

```text
dist/QuoteableQuotes.saver
```

Install to System Settings:

```bash
scripts/install-saver.sh
```

Then open `System Settings -> Screen Saver` and select `Quoteable Quotes`.

## Options
Use `ScreenSaver -> Options...` in standalone app, or `Options...` in Screen Saver settings.

Implemented options:
- Font family picker (with live font-face preview in dropdown)
- Font color picker
- Font size slider
- Background mode:
  - Solid color
  - Bundled image
  - Custom image (`jpg/png/bmp/gif`)
- Bundled background picker
- Custom background file picker
- Quote theme picker (bundled XML libraries)
- Custom quote XML picker
- Base quote time slider
- Animation style picker (`Random Transition` included)
- Attribution show/hide toggle

## Quote Source
Fallback order:
1. Custom XML file selected in options
2. Bundled themed XML selected in options
3. Hardcoded fallback quotes

Supported XML shape:

```xml
<QUOTES>
    <Quote>
        <body>...</body>
        <author>...</author>
        <theme>...</theme>
        <font>...</font>
        <attribution>Work Title (Year) | URL</attribution>
    </Quote>
</QUOTES>
```

Bundled libraries:
- `quotes.xml` (mixed)
- `leadership-quotes.xml`
- `stoicism-quotes.xml`
- `comedic-quotes.xml`
- `greek-philosophers-quotes.xml`
- `french-revolutionaries-quotes.xml`

Runtime behavior:
- Quotes are randomized.
- No repeats until the full selected set is shown.
- Dynamic timing scales from the configured base time.
- Hotkeys are currently disabled and deferred to Milestone 7.

## Test

```bash
swift test
```

## Direct Release Binary

```text
.build/arm64-apple-macosx/release/ScreenSaver
```
