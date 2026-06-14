# Installing Quoteable Quotes

Quoteable Quotes ships as a macOS `.saver` bundle.

## Requirements

- macOS 13 or newer
- Xcode command line tools if building from source

## Install From a Release

1. Download `QuoteableQuotes-v1.0.0.saver.zip` from the release page.
2. Unzip it.
3. Double-click `QuoteableQuotes.saver`.
4. Choose whether to install it for the current user.
5. Open `System Settings -> Wallpaper -> Screen Saver`.
6. Select `Quoteable Quotes`.

If macOS blocks the bundle because it is locally/ad-hoc signed, open `System Settings -> Privacy & Security` and allow it from there.

## Build and Install From Source

From the repository root:

```bash
scripts/build-saver.sh
scripts/install-saver.sh
```

Then open `System Settings -> Wallpaper -> Screen Saver` and select `Quoteable Quotes`.

## Configure

Use `Options...` in Screen Saver settings to choose:

- Font family, font color, and font size
- Solid, bundled, or custom image background
- Bundled quote library or custom XML file
- Animation style and base quote timing
- Attribution visibility

Custom quote XML uses this shape:

```xml
<QUOTES>
    <Quote>
        <body>Quote body</body>
        <author>Author name</author>
        <theme>optional theme</theme>
        <font>optional font suggestion</font>
        <attribution>optional source note</attribution>
    </Quote>
</QUOTES>
```
