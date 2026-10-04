# ScreenSaver for macOS
## Quoteable Quotes

This is the working sketch for a macOS quote screensaver (Swift + AppKit + SwiftPM).
Build target is now **release-first** (`swift build -c release`, `swift run -c release ...`).

The quote source is XML. Current supported quote shape:

```xml
<QUOTES>
    <Quote>
        <body>Quote body</body>
        <author>Author name</author>
        <theme>leadership</theme>
        <font>Avenir Next</font>
        <attribution>Work Title (Year) | URL</attribution>
    </Quote>
</QUOTES>
```

## Milestones

### Milestone 1
Status: Complete
 - Create the program with white text in papyrus font over solid black background.
 - Include four hardcoded quotes. (drawn from the internet. ask for access)
 - Time of 5 seconds per quote.
 - Fade out transition.
### Milestone 2
Status: Complete
 - Add options tab to change the background color, font, foreground color, and font size.
 - font change should be a Microsoft Office style with the fonts depicted in a dropdown.
 - background change should be a color wheel style.
 - foreground/font color should be selectable via a color wheel style picker.
 - font size should be adjustable with a slider control.

### Milestone 3
Status: Complete
 - Move quotes from hardcoded values to an XML quote file source.
 - Add option in settings/options to select a custom XML quote file.
 - Add bundled themed XML libraries and a Theme picker in options:
   - Mixed (Default)
   - Leadership
   - Stoicism
   - Comedic
   - Greek Philosophers
   - French Revolutionaries
 - Add quote metadata support in XML:
   - `theme`
   - `font`
   - `attribution`
 - Make the default `quotes.xml` a true mixed library:
   - 20 quotes from each theme file (100 total).
 - Keep a hardcoded fallback sample:
   - 2 quotes from each theme (10 total) used only if XML loading fails.
 - Runtime quote rotation behavior:
   - Randomized display order.
   - No repeats until all quotes in the selected source have been shown.
 - Add background image support for jpg/png/bmp/gif.
     - Include a starter set of bundled background images in the package.

### Milestone 4
Status: Complete
 - As some quotes are longer than others and require more time to absorb:
    - programmatically adjust display time to the length of the <quote> string, ie for a seven word string, 5 secs (current default) should be enough.  For a 13 word string, 8 secs should be right.. continue in this vein to a 24 word string.. 
 - Add animation style selection (instead of fade-only):
    1. Drop down from top.
    2. Slide in from left/right.
    3. Materialize in center.
    4. Genie from top-left/right or bottom/top.
    5. Transparent start, then flag-wave into existence.
 - Add a time option to the dialog.
    - change the time the quote display (currently 5 sec.)

### Milestone 5
Status: Complete
 - option to show `attribution` at the bottom right of the screen.
    - in a smaller size than the quote
    - in a different font, I think tahoma or arial narrow

## Milestone 6
Status: Complete
 -  Clean up project folder. I moved the sample backgrounds to Resources/images folder. 
    -  These should be bundled in the package
 
 **Screensaver** implementation.  
    - make the standalone swift app a full fledged screensaver bundle

## Current Baseline Notes
- Background picture functionality (bundled + custom) is implemented and repaired in both standalone and `.saver` targets.
- Font face/color/size, animation styles, attribution toggle, and XML theme/source selection are all active.
