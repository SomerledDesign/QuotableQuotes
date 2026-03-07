import AppKit
import Foundation
import QuartzCore
import ScreenSaver
import UniformTypeIdentifiers

/// Runtime quote model used by the `.saver` bundle.
private struct SaverQuote {
    let body: String
    let author: String
    let attribution: String?

    var wordCount: Int {
        body.split { !$0.isLetter && !$0.isNumber }.count
    }
}

/// XML parser for `.saver` quote resources.
///
/// Supports keyed entries (`<body>`, `<author>`, `<attribution>`) and legacy
/// quote/author pair format.
private final class SaverQuoteParser: NSObject, XMLParserDelegate {
    private var currentElement: String?
    private var currentText = ""

    private var buildingBody: String?
    private var buildingAuthor: String?
    private var buildingAttribution: String?
    private var insideQuote = false
    private var pendingBody: String?

    private(set) var quotes: [SaverQuote] = []

    /// Parses XML data into saver quote records.
    /// - Parameter data: Raw XML bytes.
    /// - Returns: Parsed quote array.
    func parse(data: Data) -> [SaverQuote] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { return [] }
        return quotes
    }

    /// XML parser start-element callback.
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let key = elementName.lowercased()
        if key == "quote" {
            insideQuote = true
            buildingBody = nil
            buildingAuthor = nil
            buildingAttribution = nil
            currentElement = key
            currentText = ""
            return
        }

        if key == "author" || key == "body" || key == "attribution" {
            currentElement = key
            currentText = ""
        }
    }

    /// XML parser character callback.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentElement != nil else { return }
        currentText += string
    }

    /// XML parser end-element callback.
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let key = elementName.lowercased()
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if key == "body" {
            if !text.isEmpty { buildingBody = text }
        } else if key == "attribution" {
            if !text.isEmpty { buildingAttribution = text }
        } else if key == "quote" {
            if let body = buildingBody, !body.isEmpty, let author = buildingAuthor, !author.isEmpty {
                quotes.append(SaverQuote(body: body, author: author, attribution: buildingAttribution))
            } else if !text.isEmpty {
                pendingBody = text
            }
            insideQuote = false
        } else if key == "author", insideQuote {
            if !text.isEmpty { buildingAuthor = text }
        } else if key == "author", let body = pendingBody, !body.isEmpty, !text.isEmpty {
            quotes.append(SaverQuote(body: body, author: text, attribution: nil))
            pendingBody = nil
        }

        if key == "quote" || key == "author" || key == "body" || key == "attribution" {
            currentElement = nil
            currentText = ""
        }
    }
}

/// Main ScreenSaverView implementation for the `QuoteableQuotes.saver` bundle.
///
/// Handles quote loading, randomized playback, transitions, settings UI, and
/// background rendering inside the macOS Screen Saver host process.
@objc(QuoteableQuotesView)
final class QuoteableQuotesView: ScreenSaverView {
    private enum Keys {
        static let fontName = "fontName"
        static let fontSize = "fontSize"
        static let animationStyle = "animationStyle"
        static let foregroundColorData = "foregroundColorData"
        static let backgroundMode = "backgroundMode"
        static let backgroundColorData = "backgroundColorData"
        static let bundledBackgroundFileName = "bundledBackgroundFileName"
        static let customBackgroundFilePath = "customBackgroundFilePath"
        static let customBackgroundBookmarkData = "customBackgroundBookmarkData"
        static let baseSeconds = "baseQuoteSeconds"
        static let showsAttribution = "showsAttribution"
        static let bundledQuoteFileName = "bundledQuoteFileName"
        static let customQuoteFilePath = "customQuoteFilePath"
        static let customQuoteBookmarkData = "customQuoteBookmarkData"
    }

    private enum BackgroundMode: String {
        case solid
        case bundledImage
        case customImage
    }

    private enum AnimationStyle: String, CaseIterable {
        case randomTransition
        case fade
        case dropDown
        case slide
        case materialize
        case genie
        case flagWave

        var title: String {
            switch self {
            case .randomTransition: return "Random Transition"
            case .fade: return "Fade"
            case .dropDown: return "Drop Down From Top"
            case .slide: return "Slide In From Left/Right"
            case .materialize: return "Materialize In Center"
            case .genie: return "Genie From Corner"
            case .flagWave: return "Transparent + Flag Wave"
            }
        }
    }

    private struct BundledBackground {
        let title: String
        let fileName: String
    }

    private struct BundledTheme {
        let title: String
        let fileName: String
    }

    private static let bundledBackgrounds: [BundledBackground] = [
        BundledBackground(title: "Antique Parchment", fileName: "images/antique-parchment.png"),
        BundledBackground(title: "Gray Linen", fileName: "images/gray-linen.png"),
        BundledBackground(title: "Offwhite Fabric", fileName: "images/offwhite-fabric-texture.png"),
        BundledBackground(title: "Old Papyrus", fileName: "images/old-papyrus.png"),
        BundledBackground(title: "Old Parchment", fileName: "images/old-parchment.png"),
        BundledBackground(title: "White Paper", fileName: "images/white-paper.png")
    ]

    private static let bundledThemes: [BundledTheme] = [
        BundledTheme(title: "Mixed (Default)", fileName: "quotes.xml"),
        BundledTheme(title: "Leadership", fileName: "leadership-quotes.xml"),
        BundledTheme(title: "Stoicism", fileName: "stoicism-quotes.xml"),
        BundledTheme(title: "Comedic", fileName: "comedic-quotes.xml"),
        BundledTheme(title: "Greek Philosophers", fileName: "greek-philosophers-quotes.xml"),
        BundledTheme(title: "French Revolutionaries", fileName: "french-revolutionaries-quotes.xml")
    ]

    private let saverDefaults = ScreenSaverDefaults(forModuleWithName: "com.kmurphy.QuoteableQuotes")

    private let colorBackgroundView = NSView()
    private let backgroundImageView = NSImageView()
    private let quoteLabel = NSTextField(labelWithString: "")
    private let attributionLabel = NSTextField(labelWithString: "")

    private var quotes: [SaverQuote] = []
    private var drawOrder: [Int] = []
    private var drawIndex = 0

    private var currentQuote: SaverQuote?

    private var rotationTimer: Timer?
    private var runtimeCustomBackgroundURL: URL?
    private var lastStyleFingerprint: String?
    private var lastQuoteSourceFingerprint: String?

    private var configWindow: NSWindow?
    private var detachedConfigWindow: NSWindow?
    private var fontPicker: NSPopUpButton?
    private var animationStylePicker: NSPopUpButton?
    private var foregroundWell: NSColorWell?
    private var fontSizeSlider: NSSlider?
    private var fontSizeValueLabel: NSTextField?
    private var backgroundModePicker: NSPopUpButton?
    private var backgroundColorWell: NSColorWell?
    private var bundledBackgroundPicker: NSPopUpButton?
    private var customBackgroundPathLabel: NSTextField?
    private var quoteThemePicker: NSPopUpButton?
    private var quotePathLabel: NSTextField?
    private var baseTimeSlider: NSSlider?
    private var baseTimeValueLabel: NSTextField?
    private var showAttributionCheckbox: NSButton?

    /// Creates saver view for runtime/preview host.
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        registerDefaults()
        configureView()
        loadQuotes()
        showNextQuote(animated: false)
        scheduleNext()
    }

    /// Creates saver view from coder path.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerDefaults()
        configureView()
        loadQuotes()
        showNextQuote(animated: false)
        scheduleNext()
    }

    /// The view can accept first-responder status for host event routing.
    override var acceptsFirstResponder: Bool { true }
    /// Requests first-responder status.
    override func becomeFirstResponder() -> Bool { true }

    /// Indicates options sheet support.
    override var hasConfigureSheet: Bool { true }

    /// Returns and refreshes the options/configuration sheet.
    override var configureSheet: NSWindow? {
        if configWindow == nil {
            configWindow = makeConfigureWindow()
        }
        refreshConfigControls()
        return configWindow
    }

    /// ScreenSaverView animation lifecycle start.
    override func startAnimation() {
        super.startAnimation()
        window?.makeFirstResponder(self)
        scheduleNext()
    }

    /// ScreenSaverView animation lifecycle stop.
    override func stopAnimation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
        super.stopAnimation()
    }

    /// Per-frame callback used to detect live settings changes.
    override func animateOneFrame() {
        syncLiveSettingsIfNeeded()
    }

    /// Registers default values for saver settings.
    private func registerDefaults() {
        let fgData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor.white, requiringSecureCoding: true)
        let bgData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor.black, requiringSecureCoding: true)
        saverDefaults?.register(defaults: [
            Keys.fontName: "Papyrus",
            Keys.fontSize: 48.0,
            Keys.animationStyle: AnimationStyle.randomTransition.rawValue,
            Keys.baseSeconds: 5.0,
            Keys.showsAttribution: true,
            Keys.backgroundMode: BackgroundMode.bundledImage.rawValue,
            Keys.bundledBackgroundFileName: "images/old-parchment.png",
            Keys.bundledQuoteFileName: "quotes.xml",
            Keys.foregroundColorData: fgData as Any,
            Keys.backgroundColorData: bgData as Any
        ])
        saverDefaults?.synchronize()
    }

    /// Builds renderer subviews and constraints.
    private func configureView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        colorBackgroundView.wantsLayer = true
        colorBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(colorBackgroundView)

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.imageScaling = .scaleAxesIndependently
        backgroundImageView.animates = true
        addSubview(backgroundImageView)

        quoteLabel.alignment = .center
        quoteLabel.maximumNumberOfLines = 0
        quoteLabel.lineBreakMode = .byWordWrapping
        quoteLabel.wantsLayer = true
        quoteLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(quoteLabel)

        attributionLabel.alignment = .right
        attributionLabel.maximumNumberOfLines = 2
        attributionLabel.lineBreakMode = .byTruncatingTail
        attributionLabel.translatesAutoresizingMaskIntoConstraints = false
        attributionLabel.isHidden = true
        addSubview(attributionLabel)

        NSLayoutConstraint.activate([
            colorBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            colorBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            colorBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            colorBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            quoteLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 80),
            quoteLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -80),
            quoteLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            quoteLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 40),
            quoteLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -40),

            attributionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            attributionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            attributionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 220)
        ])

        applyBackground()
    }

    /// Loads quotes from custom XML, bundled XML, then fallback quote.
    private func loadQuotes() {
        let customPath = saverDefaults?.string(forKey: Keys.customQuoteFilePath)
        let bundledFile = saverDefaults?.string(forKey: Keys.bundledQuoteFileName) ?? "quotes.xml"

        if let customURL = resolvedCustomQuoteURL(customPath: customPath) {
            if let data = try? Data(contentsOf: customURL) {
                let parsed = SaverQuoteParser().parse(data: data)
                if !parsed.isEmpty { quotes = parsed }
            }
        }

        if quotes.isEmpty,
           let url = Bundle(for: type(of: self)).url(forResource: URL(fileURLWithPath: bundledFile).deletingPathExtension().lastPathComponent, withExtension: "xml"),
           let data = try? Data(contentsOf: url) {
            let parsed = SaverQuoteParser().parse(data: data)
            if !parsed.isEmpty { quotes = parsed }
        }

        if quotes.isEmpty {
            quotes = [SaverQuote(body: "No quotes configured.", author: "Quoteable Quotes", attribution: nil)]
        }

        drawOrder = Array(quotes.indices).shuffled()
        drawIndex = 0
    }

    /// Returns next quote from non-repeating shuffled deck.
    private func nextFromDeck() -> SaverQuote {
        if drawOrder.isEmpty || drawIndex >= drawOrder.count {
            drawOrder = Array(quotes.indices).shuffled()
            drawIndex = 0
        }
        let quote = quotes[drawOrder[drawIndex]]
        drawIndex += 1
        return quote
    }

    /// Advances to next quote and renders it.
    /// - Parameter animated: Whether transition should animate.
    private func showNextQuote(animated: Bool) {
        let nextQuote = nextFromDeck()
        transitionToQuote(nextQuote, animated: animated)
    }

    /// Renders and transitions to the provided quote.
    /// - Parameters:
    ///   - quote: Quote to display.
    ///   - animated: Whether to animate the transition.
    private func transitionToQuote(_ quote: SaverQuote, animated: Bool) {
        currentQuote = quote

        let fontName = saverDefaults?.string(forKey: Keys.fontName) ?? "Papyrus"
        let quoteSize = CGFloat(saverDefaults?.double(forKey: Keys.fontSize) ?? 48)
        let textColor = configuredForegroundColor()

        let quoteFont = NSFont(name: fontName, size: quoteSize) ?? NSFont.systemFont(ofSize: quoteSize, weight: .medium)
        let authorSize = max(14, round(quoteSize * 0.58))
        let authorFont = NSFont(name: fontName, size: authorSize) ?? NSFont.systemFont(ofSize: authorSize, weight: .regular)
        let attributionFont = NSFont(name: "Arial Narrow", size: max(12, round(quoteSize * 0.34)))
            ?? NSFont(name: "Tahoma", size: max(12, round(quoteSize * 0.34)))
            ?? NSFont.systemFont(ofSize: max(12, round(quoteSize * 0.34)), weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.paragraphSpacing = 14

        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        let authorAttrs: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]

        let text = NSMutableAttributedString(string: quote.body, attributes: quoteAttrs)
        text.append(NSAttributedString(string: "\n- \(quote.author)", attributes: authorAttrs))

        let updateBlock = {
            self.quoteLabel.attributedStringValue = text
            let showsAttribution = self.saverDefaults?.bool(forKey: Keys.showsAttribution) ?? true
            if showsAttribution, let attribution = quote.attribution, !attribution.isEmpty {
                self.attributionLabel.font = attributionFont
                self.attributionLabel.textColor = textColor.withAlphaComponent(0.84)
                self.attributionLabel.stringValue = attribution
                self.attributionLabel.isHidden = false
            } else {
                self.attributionLabel.stringValue = ""
                self.attributionLabel.isHidden = true
            }
        }

        guard animated else {
            resetVisualState()
            updateBlock()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            quoteLabel.animator().alphaValue = 0
            attributionLabel.animator().alphaValue = 0
        } completionHandler: {
            updateBlock()
            self.animateQuoteEntrance(style: self.configuredAnimationStyle())
        }
    }

    /// Restores visual state to steady defaults.
    private func resetVisualState() {
        quoteLabel.alphaValue = 1
        attributionLabel.alphaValue = 1
        quoteLabel.layer?.transform = CATransform3DIdentity
    }

    /// Schedules next quote rotation based on configured base time and word count.
    private func scheduleNext() {
        rotationTimer?.invalidate()
        guard let quote = currentQuote else { return }

        let base = saverDefaults?.double(forKey: Keys.baseSeconds) ?? 5.0
        let words = max(quote.wordCount, 7)
        let extra = min(Double(words - 7) * 0.5, 10.0)
        let interval = min(max(base + extra, 3.0), 30.0)

        rotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.showNextQuote(animated: true)
            self.scheduleNext()
        }
    }

    /// Reads configured foreground text color.
    private func configuredForegroundColor() -> NSColor {
        guard
            let data = saverDefaults?.data(forKey: Keys.foregroundColorData),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        else { return .white }
        return color
    }

    /// Reads configured background solid color.
    private func configuredBackgroundColor() -> NSColor {
        guard
            let data = saverDefaults?.data(forKey: Keys.backgroundColorData),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        else { return .black }
        return color
    }

    /// Reads configured animation style with fallback.
    private func configuredAnimationStyle() -> AnimationStyle {
        let raw = saverDefaults?.string(forKey: Keys.animationStyle) ?? AnimationStyle.randomTransition.rawValue
        return AnimationStyle(rawValue: raw) ?? .randomTransition
    }

    /// Applies currently selected background mode.
    private func applyBackground() {
        let modeRaw = saverDefaults?.string(forKey: Keys.backgroundMode) ?? BackgroundMode.bundledImage.rawValue
        let mode = BackgroundMode(rawValue: modeRaw) ?? .bundledImage

        switch mode {
        case .solid:
            backgroundImageView.image = nil
            backgroundImageView.isHidden = true
            colorBackgroundView.layer?.backgroundColor = configuredBackgroundColor().cgColor
        case .bundledImage:
            let fileName = saverDefaults?.string(forKey: Keys.bundledBackgroundFileName) ?? "images/old-parchment.png"
            if let image = loadBundledBackgroundImage(fileName: fileName) {
                backgroundImageView.image = image
                backgroundImageView.isHidden = false
                colorBackgroundView.layer?.backgroundColor = NSColor.black.cgColor
            } else {
                backgroundImageView.image = nil
                backgroundImageView.isHidden = true
                colorBackgroundView.layer?.backgroundColor = configuredBackgroundColor().cgColor
            }
        case .customImage:
            let path = saverDefaults?.string(forKey: Keys.customBackgroundFilePath)
            if let url = resolvedCustomBackgroundURL(customPath: path), let image = NSImage(contentsOf: url) {
                backgroundImageView.image = image
                backgroundImageView.isHidden = false
                colorBackgroundView.layer?.backgroundColor = NSColor.black.cgColor
            } else {
                backgroundImageView.image = nil
                backgroundImageView.isHidden = true
                colorBackgroundView.layer?.backgroundColor = configuredBackgroundColor().cgColor
            }
        }
    }

    /// Loads bundled background image from saver resources.
    /// - Parameter fileName: Relative resource path.
    /// - Returns: Decoded image or `nil`.
    private func loadBundledBackgroundImage(fileName: String) -> NSImage? {
        let normalized = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let fileURL = URL(fileURLWithPath: normalized)
        let name = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var subdirectory = fileURL.deletingLastPathComponent().path
        if subdirectory == "." {
            subdirectory = ""
        } else if subdirectory.hasPrefix("/") {
            subdirectory.removeFirst()
        }
        let lookupSubdirectory = subdirectory.isEmpty ? nil : subdirectory

        let bundle = Bundle(for: type(of: self))
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: lookupSubdirectory),
           let image = NSImage(contentsOf: url) {
            return image
        }
        if let directURL = bundle.url(forResource: normalized, withExtension: nil),
           let image = NSImage(contentsOf: directURL) {
            return image
        }
        return nil
    }

    /// Creates the detached/options configuration window.
    private func makeConfigureWindow() -> NSWindow {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 810),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "Quoteable Quotes Options"
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.hidesOnDeactivate = false
        window.worksWhenModal = true

        let root = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 810))

        let fontLabel = NSTextField(labelWithString: "Font")
        fontLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        fontLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(fontLabel)

        let fontPicker = NSPopUpButton()
        fontPicker.translatesAutoresizingMaskIntoConstraints = false
        fontPicker.addItems(withTitles: NSFontManager.shared.availableFontFamilies.sorted())
        fontPicker.target = self
        fontPicker.action = #selector(fontChanged(_:))
        applyFontPreview(to: fontPicker)
        self.fontPicker = fontPicker
        root.addSubview(fontPicker)

        let bgModeLabel = NSTextField(labelWithString: "Background Mode")
        bgModeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        bgModeLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bgModeLabel)

        let bgModePicker = NSPopUpButton()
        bgModePicker.translatesAutoresizingMaskIntoConstraints = false
        bgModePicker.addItems(withTitles: ["Solid Color", "Bundled Image", "Custom Image"])
        bgModePicker.target = self
        bgModePicker.action = #selector(backgroundModeChanged(_:))
        self.backgroundModePicker = bgModePicker
        root.addSubview(bgModePicker)

        let bundledBgLabel = NSTextField(labelWithString: "Bundled Background")
        bundledBgLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        bundledBgLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bundledBgLabel)

        let bundledBgPicker = NSPopUpButton()
        bundledBgPicker.translatesAutoresizingMaskIntoConstraints = false
        bundledBgPicker.addItems(withTitles: Self.bundledBackgrounds.map(\.title))
        bundledBgPicker.target = self
        bundledBgPicker.action = #selector(bundledBackgroundChanged(_:))
        self.bundledBackgroundPicker = bundledBgPicker
        root.addSubview(bundledBgPicker)

        let customBgPath = NSTextField(labelWithString: "No custom image selected")
        customBgPath.font = .systemFont(ofSize: 12)
        customBgPath.textColor = .secondaryLabelColor
        customBgPath.lineBreakMode = .byTruncatingMiddle
        customBgPath.translatesAutoresizingMaskIntoConstraints = false
        self.customBackgroundPathLabel = customBgPath
        root.addSubview(customBgPath)

        let chooseBgButton = NSButton(title: "Choose Image...", target: self, action: #selector(chooseBackgroundImage(_:)))
        chooseBgButton.bezelStyle = .rounded
        chooseBgButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(chooseBgButton)

        let clearBgButton = NSButton(title: "Clear Custom", target: self, action: #selector(clearCustomBackground(_:)))
        clearBgButton.bezelStyle = .rounded
        clearBgButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(clearBgButton)

        let bgColorLabel = NSTextField(labelWithString: "Background Color")
        bgColorLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        bgColorLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bgColorLabel)

        let bgColorWell = NSColorWell()
        bgColorWell.translatesAutoresizingMaskIntoConstraints = false
        bgColorWell.target = self
        bgColorWell.action = #selector(backgroundColorChanged(_:))
        self.backgroundColorWell = bgColorWell
        root.addSubview(bgColorWell)

        let fgLabel = NSTextField(labelWithString: "Font Color")
        fgLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        fgLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(fgLabel)

        let fgWell = NSColorWell()
        fgWell.translatesAutoresizingMaskIntoConstraints = false
        fgWell.target = self
        fgWell.action = #selector(foregroundColorChanged(_:))
        self.foregroundWell = fgWell
        root.addSubview(fgWell)

        let fontSizeLabel = NSTextField(labelWithString: "Font Size")
        fontSizeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        fontSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(fontSizeLabel)

        let fontSizeSlider = NSSlider(value: 48, minValue: 18, maxValue: 140, target: self, action: #selector(fontSizeChanged(_:)))
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        self.fontSizeSlider = fontSizeSlider
        root.addSubview(fontSizeSlider)

        let fontSizeValueLabel = NSTextField(labelWithString: "48")
        fontSizeValueLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        fontSizeValueLabel.textColor = .secondaryLabelColor
        fontSizeValueLabel.alignment = .right
        fontSizeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.fontSizeValueLabel = fontSizeValueLabel
        root.addSubview(fontSizeValueLabel)

        let animationLabel = NSTextField(labelWithString: "Animation Style")
        animationLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        animationLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(animationLabel)

        let animationPicker = NSPopUpButton()
        animationPicker.translatesAutoresizingMaskIntoConstraints = false
        animationPicker.addItems(withTitles: AnimationStyle.allCases.map(\.title))
        animationPicker.target = self
        animationPicker.action = #selector(animationStyleChanged(_:))
        self.animationStylePicker = animationPicker
        root.addSubview(animationPicker)

        let quoteThemeLabel = NSTextField(labelWithString: "Theme")
        quoteThemeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        quoteThemeLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(quoteThemeLabel)

        let quoteThemePicker = NSPopUpButton()
        quoteThemePicker.translatesAutoresizingMaskIntoConstraints = false
        quoteThemePicker.addItems(withTitles: Self.bundledThemes.map(\.title))
        quoteThemePicker.target = self
        quoteThemePicker.action = #selector(quoteThemeChanged(_:))
        self.quoteThemePicker = quoteThemePicker
        root.addSubview(quoteThemePicker)

        let quotePathLabel = NSTextField(labelWithString: "Using bundled quotes.xml")
        quotePathLabel.font = .systemFont(ofSize: 12)
        quotePathLabel.textColor = .secondaryLabelColor
        quotePathLabel.lineBreakMode = .byTruncatingMiddle
        quotePathLabel.translatesAutoresizingMaskIntoConstraints = false
        self.quotePathLabel = quotePathLabel
        root.addSubview(quotePathLabel)

        let chooseXMLButton = NSButton(title: "Choose XML...", target: self, action: #selector(chooseXMLFile(_:)))
        chooseXMLButton.bezelStyle = .rounded
        chooseXMLButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(chooseXMLButton)

        let useBundledButton = NSButton(title: "Use Bundled", target: self, action: #selector(useBundledQuotes(_:)))
        useBundledButton.bezelStyle = .rounded
        useBundledButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(useBundledButton)

        let baseLabel = NSTextField(labelWithString: "Base Quote Time (sec)")
        baseLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        baseLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(baseLabel)

        let baseSlider = NSSlider(value: 5, minValue: 3, maxValue: 20, target: self, action: #selector(baseTimeChanged(_:)))
        baseSlider.translatesAutoresizingMaskIntoConstraints = false
        self.baseTimeSlider = baseSlider
        root.addSubview(baseSlider)

        let baseValueLabel = NSTextField(labelWithString: "5.0")
        baseValueLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        baseValueLabel.textColor = .secondaryLabelColor
        baseValueLabel.alignment = .right
        baseValueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.baseTimeValueLabel = baseValueLabel
        root.addSubview(baseValueLabel)

        let attributionCheck = NSButton(checkboxWithTitle: "Show Attribution (bottom-right)", target: self, action: #selector(showAttributionChanged(_:)))
        attributionCheck.translatesAutoresizingMaskIntoConstraints = false
        self.showAttributionCheckbox = attributionCheck
        root.addSubview(attributionCheck)

        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeConfigureSheet(_:)))
        doneButton.bezelStyle = .rounded
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(doneButton)

        let detachButton = NSButton(title: "Detach Window", target: self, action: #selector(detachConfigureWindow(_:)))
        detachButton.bezelStyle = .rounded
        detachButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(detachButton)

        NSLayoutConstraint.activate([
            fontLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            fontLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 20),

            fontPicker.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            fontPicker.topAnchor.constraint(equalTo: fontLabel.bottomAnchor, constant: 8),
            fontPicker.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            bgModeLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            bgModeLabel.topAnchor.constraint(equalTo: fontPicker.bottomAnchor, constant: 16),

            bgModePicker.leadingAnchor.constraint(equalTo: bgModeLabel.leadingAnchor),
            bgModePicker.topAnchor.constraint(equalTo: bgModeLabel.bottomAnchor, constant: 8),
            bgModePicker.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            bundledBgLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            bundledBgLabel.topAnchor.constraint(equalTo: bgModePicker.bottomAnchor, constant: 12),

            bundledBgPicker.leadingAnchor.constraint(equalTo: bundledBgLabel.leadingAnchor),
            bundledBgPicker.topAnchor.constraint(equalTo: bundledBgLabel.bottomAnchor, constant: 8),
            bundledBgPicker.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            customBgPath.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            customBgPath.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            customBgPath.topAnchor.constraint(equalTo: bundledBgPicker.bottomAnchor, constant: 8),

            chooseBgButton.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            chooseBgButton.topAnchor.constraint(equalTo: customBgPath.bottomAnchor, constant: 8),

            clearBgButton.leadingAnchor.constraint(equalTo: chooseBgButton.trailingAnchor, constant: 10),
            clearBgButton.centerYAnchor.constraint(equalTo: chooseBgButton.centerYAnchor),

            bgColorLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            bgColorLabel.topAnchor.constraint(equalTo: chooseBgButton.bottomAnchor, constant: 12),

            bgColorWell.leadingAnchor.constraint(equalTo: bgColorLabel.leadingAnchor),
            bgColorWell.topAnchor.constraint(equalTo: bgColorLabel.bottomAnchor, constant: 8),
            bgColorWell.widthAnchor.constraint(equalToConstant: 72),
            bgColorWell.heightAnchor.constraint(equalToConstant: 30),

            fgLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            fgLabel.topAnchor.constraint(equalTo: bgColorWell.bottomAnchor, constant: 12),

            fgWell.leadingAnchor.constraint(equalTo: fgLabel.leadingAnchor),
            fgWell.topAnchor.constraint(equalTo: fgLabel.bottomAnchor, constant: 8),
            fgWell.widthAnchor.constraint(equalToConstant: 72),
            fgWell.heightAnchor.constraint(equalToConstant: 30),

            fontSizeLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            fontSizeLabel.topAnchor.constraint(equalTo: fgWell.bottomAnchor, constant: 12),

            fontSizeSlider.leadingAnchor.constraint(equalTo: fontSizeLabel.leadingAnchor),
            fontSizeSlider.topAnchor.constraint(equalTo: fontSizeLabel.bottomAnchor, constant: 8),
            fontSizeSlider.trailingAnchor.constraint(equalTo: fontSizeValueLabel.leadingAnchor, constant: -10),

            fontSizeValueLabel.centerYAnchor.constraint(equalTo: fontSizeSlider.centerYAnchor),
            fontSizeValueLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 44),

            animationLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            animationLabel.topAnchor.constraint(equalTo: fontSizeSlider.bottomAnchor, constant: 12),

            animationPicker.leadingAnchor.constraint(equalTo: animationLabel.leadingAnchor),
            animationPicker.topAnchor.constraint(equalTo: animationLabel.bottomAnchor, constant: 8),
            animationPicker.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            quoteThemeLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            quoteThemeLabel.topAnchor.constraint(equalTo: animationPicker.bottomAnchor, constant: 12),

            quoteThemePicker.leadingAnchor.constraint(equalTo: quoteThemeLabel.leadingAnchor),
            quoteThemePicker.topAnchor.constraint(equalTo: quoteThemeLabel.bottomAnchor, constant: 8),
            quoteThemePicker.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            quotePathLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            quotePathLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            quotePathLabel.topAnchor.constraint(equalTo: quoteThemePicker.bottomAnchor, constant: 8),

            chooseXMLButton.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            chooseXMLButton.topAnchor.constraint(equalTo: quotePathLabel.bottomAnchor, constant: 8),

            useBundledButton.leadingAnchor.constraint(equalTo: chooseXMLButton.trailingAnchor, constant: 10),
            useBundledButton.centerYAnchor.constraint(equalTo: chooseXMLButton.centerYAnchor),

            baseLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            baseLabel.topAnchor.constraint(equalTo: chooseXMLButton.bottomAnchor, constant: 12),

            baseSlider.leadingAnchor.constraint(equalTo: baseLabel.leadingAnchor),
            baseSlider.topAnchor.constraint(equalTo: baseLabel.bottomAnchor, constant: 8),
            baseSlider.trailingAnchor.constraint(equalTo: baseValueLabel.leadingAnchor, constant: -10),

            baseValueLabel.centerYAnchor.constraint(equalTo: baseSlider.centerYAnchor),
            baseValueLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            baseValueLabel.widthAnchor.constraint(equalToConstant: 44),

            attributionCheck.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            attributionCheck.topAnchor.constraint(equalTo: baseSlider.bottomAnchor, constant: 12),
            doneButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),

            detachButton.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -10),
            detachButton.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor)
        ])

        window.contentView = root
        refreshConfigControls()
        return window
    }

    /// Syncs configuration controls from persisted defaults.
    private func refreshConfigControls() {
        let fontName = saverDefaults?.string(forKey: Keys.fontName) ?? "Papyrus"
        if let picker = fontPicker, let idx = picker.itemTitles.firstIndex(of: fontName) {
            picker.selectItem(at: idx)
        }

        if let idx = AnimationStyle.allCases.firstIndex(of: configuredAnimationStyle()) {
            animationStylePicker?.selectItem(at: idx)
        }

        foregroundWell?.color = configuredForegroundColor()
        backgroundColorWell?.color = configuredBackgroundColor()

        let fontSize = saverDefaults?.double(forKey: Keys.fontSize) ?? 48
        fontSizeSlider?.doubleValue = fontSize
        fontSizeValueLabel?.stringValue = "\(Int(fontSize))"

        let modeRaw = saverDefaults?.string(forKey: Keys.backgroundMode) ?? BackgroundMode.bundledImage.rawValue
        let mode = BackgroundMode(rawValue: modeRaw) ?? .bundledImage
        switch mode {
        case .solid: backgroundModePicker?.selectItem(at: 0)
        case .bundledImage: backgroundModePicker?.selectItem(at: 1)
        case .customImage: backgroundModePicker?.selectItem(at: 2)
        }

        let bundledBG = saverDefaults?.string(forKey: Keys.bundledBackgroundFileName) ?? "images/old-parchment.png"
        if let idx = Self.bundledBackgrounds.firstIndex(where: { $0.fileName == bundledBG }) {
            bundledBackgroundPicker?.selectItem(at: idx)
        }

        if let path = saverDefaults?.string(forKey: Keys.customBackgroundFilePath), !path.isEmpty {
            customBackgroundPathLabel?.stringValue = path
        } else {
            customBackgroundPathLabel?.stringValue = "No custom image selected"
        }

        let bundledTheme = saverDefaults?.string(forKey: Keys.bundledQuoteFileName) ?? "quotes.xml"
        if let idx = Self.bundledThemes.firstIndex(where: { $0.fileName == bundledTheme }) {
            quoteThemePicker?.selectItem(at: idx)
        }
        if let customPath = saverDefaults?.string(forKey: Keys.customQuoteFilePath), !customPath.isEmpty {
            quotePathLabel?.stringValue = customPath
        } else {
            quotePathLabel?.stringValue = "Using bundled \(bundledTheme)"
        }

        let base = saverDefaults?.double(forKey: Keys.baseSeconds) ?? 5.0
        baseTimeSlider?.doubleValue = base
        baseTimeValueLabel?.stringValue = String(format: "%.1f", base)
        showAttributionCheckbox?.state = (saverDefaults?.bool(forKey: Keys.showsAttribution) ?? true) ? .on : .off
    }

    /// Font picker action handler.
    @objc private func fontChanged(_ sender: NSPopUpButton) {
        guard let selected = sender.selectedItem?.title else { return }
        saverDefaults?.set(selected, forKey: Keys.fontName)
        saverDefaults?.synchronize()
        transitionToQuote(currentQuote ?? nextFromDeck(), animated: false)
    }

    /// Animation-style picker action handler.
    @objc private func animationStyleChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < AnimationStyle.allCases.count else { return }
        saverDefaults?.set(AnimationStyle.allCases[idx].rawValue, forKey: Keys.animationStyle)
        saverDefaults?.synchronize()
    }

    /// Foreground color picker action handler.
    @objc private func foregroundColorChanged(_ sender: NSColorWell) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: sender.color, requiringSecureCoding: true) {
            saverDefaults?.set(data, forKey: Keys.foregroundColorData)
            saverDefaults?.synchronize()
            transitionToQuote(currentQuote ?? nextFromDeck(), animated: false)
        }
    }

    /// Font-size slider action handler.
    @objc private func fontSizeChanged(_ sender: NSSlider) {
        let rounded = Double(Int(sender.doubleValue.rounded()))
        sender.doubleValue = rounded
        saverDefaults?.set(rounded, forKey: Keys.fontSize)
        saverDefaults?.synchronize()
        fontSizeValueLabel?.stringValue = "\(Int(rounded))"
        transitionToQuote(currentQuote ?? nextFromDeck(), animated: false)
    }

    /// Background-mode picker action handler.
    @objc private func backgroundModeChanged(_ sender: NSPopUpButton) {
        let mode: BackgroundMode
        switch sender.indexOfSelectedItem {
        case 1: mode = .bundledImage
        case 2: mode = .customImage
        default: mode = .solid
        }
        saverDefaults?.set(mode.rawValue, forKey: Keys.backgroundMode)
        saverDefaults?.synchronize()
        applyBackground()
    }

    /// Solid background color action handler.
    @objc private func backgroundColorChanged(_ sender: NSColorWell) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: sender.color, requiringSecureCoding: true) {
            saverDefaults?.set(data, forKey: Keys.backgroundColorData)
            saverDefaults?.synchronize()
            applyBackground()
        }
    }

    /// Bundled background picker action handler.
    @objc private func bundledBackgroundChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < Self.bundledBackgrounds.count else { return }
        saverDefaults?.set(Self.bundledBackgrounds[idx].fileName, forKey: Keys.bundledBackgroundFileName)
        saverDefaults?.set(BackgroundMode.bundledImage.rawValue, forKey: Keys.backgroundMode)
        saverDefaults?.synchronize()
        backgroundModePicker?.selectItem(at: 1)
        applyBackground()
    }

    /// Opens file picker and stores custom background image selection.
    @objc private func chooseBackgroundImage(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .bmp, .gif]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Background"
        if panel.runModal() == .OK, let url = panel.url {
            runtimeCustomBackgroundURL = url
            saverDefaults?.set(url.path, forKey: Keys.customBackgroundFilePath)
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                saverDefaults?.set(bookmark, forKey: Keys.customBackgroundBookmarkData)
            }
            saverDefaults?.set(BackgroundMode.customImage.rawValue, forKey: Keys.backgroundMode)
            saverDefaults?.synchronize()
            customBackgroundPathLabel?.stringValue = url.path
            backgroundModePicker?.selectItem(at: 2)
            applyBackground()
        }
    }

    /// Clears custom background image selection.
    @objc private func clearCustomBackground(_ sender: NSButton) {
        runtimeCustomBackgroundURL = nil
        saverDefaults?.removeObject(forKey: Keys.customBackgroundFilePath)
        saverDefaults?.removeObject(forKey: Keys.customBackgroundBookmarkData)
        saverDefaults?.set(BackgroundMode.solid.rawValue, forKey: Keys.backgroundMode)
        saverDefaults?.synchronize()
        customBackgroundPathLabel?.stringValue = "No custom image selected"
        backgroundModePicker?.selectItem(at: 0)
        applyBackground()
    }

    /// Theme picker action handler for bundled quote libraries.
    @objc private func quoteThemeChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < Self.bundledThemes.count else { return }
        saverDefaults?.set(Self.bundledThemes[idx].fileName, forKey: Keys.bundledQuoteFileName)
        saverDefaults?.removeObject(forKey: Keys.customQuoteFilePath)
        saverDefaults?.synchronize()
        quotePathLabel?.stringValue = "Using bundled \(Self.bundledThemes[idx].fileName)"
        loadQuotes()
        showNextQuote(animated: false)
        scheduleNext()
    }

    /// Opens file picker and stores custom quote XML selection.
    @objc private func chooseXMLFile(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Quote File"
        if panel.runModal() == .OK, let url = panel.url {
            saverDefaults?.set(url.path, forKey: Keys.customQuoteFilePath)
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                saverDefaults?.set(bookmark, forKey: Keys.customQuoteBookmarkData)
            }
            saverDefaults?.synchronize()
            quotePathLabel?.stringValue = url.path
            loadQuotes()
            showNextQuote(animated: false)
            scheduleNext()
        }
    }

    /// Clears custom quote path and switches back to bundled quotes.
    @objc private func useBundledQuotes(_ sender: NSButton) {
        saverDefaults?.removeObject(forKey: Keys.customQuoteFilePath)
        saverDefaults?.removeObject(forKey: Keys.customQuoteBookmarkData)
        saverDefaults?.synchronize()
        let file = saverDefaults?.string(forKey: Keys.bundledQuoteFileName) ?? "quotes.xml"
        quotePathLabel?.stringValue = "Using bundled \(file)"
        loadQuotes()
        showNextQuote(animated: false)
        scheduleNext()
    }

    /// Base-time slider action handler.
    @objc private func baseTimeChanged(_ sender: NSSlider) {
        let rounded = (sender.doubleValue * 2).rounded() / 2
        sender.doubleValue = rounded
        saverDefaults?.set(rounded, forKey: Keys.baseSeconds)
        saverDefaults?.synchronize()
        baseTimeValueLabel?.stringValue = String(format: "%.1f", rounded)
        scheduleNext()
    }

    /// Attribution toggle action handler.
    @objc private func showAttributionChanged(_ sender: NSButton) {
        saverDefaults?.set(sender.state == .on, forKey: Keys.showsAttribution)
        saverDefaults?.synchronize()
        transitionToQuote(currentQuote ?? nextFromDeck(), animated: false)
    }

    /// Closes options sheet or detached options window.
    @objc private func closeConfigureSheet(_ sender: NSButton) {
        guard let buttonWindow = sender.window else { return }
        if let parent = buttonWindow.sheetParent {
            parent.endSheet(buttonWindow)
        } else {
            buttonWindow.orderOut(nil)
            if buttonWindow === detachedConfigWindow {
                detachedConfigWindow = nil
            }
        }
    }

    /// Detaches options sheet into a movable standalone window.
    @objc private func detachConfigureWindow(_ sender: NSButton) {
        guard let sheetWindow = sender.window else { return }
        if let parent = sheetWindow.sheetParent {
            parent.endSheet(sheetWindow)
        }
        detachedConfigWindow = makeConfigureWindow()
        detachedConfigWindow?.styleMask = [.titled, .closable]
        refreshConfigControls()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.detachedConfigWindow?.center()
            self.detachedConfigWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Resolves custom background URL from runtime URL, bookmark, or plain path.
    private func resolvedCustomBackgroundURL(customPath: String?) -> URL? {
        if let runtimeCustomBackgroundURL {
            return runtimeCustomBackgroundURL
        }
        if let bookmarkData = saverDefaults?.data(forKey: Keys.customBackgroundBookmarkData) {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                _ = url.startAccessingSecurityScopedResource()
                return url
            }
        }
        if let customPath, !customPath.isEmpty {
            let expandedPath = (customPath as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expandedPath)
        }
        return nil
    }

    /// Resolves custom quote XML URL from bookmark or plain path.
    private func resolvedCustomQuoteURL(customPath: String?) -> URL? {
        if let bookmarkData = saverDefaults?.data(forKey: Keys.customQuoteBookmarkData) {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                _ = url.startAccessingSecurityScopedResource()
                return url
            }
        }
        if let customPath, !customPath.isEmpty {
            return URL(fileURLWithPath: customPath)
        }
        return nil
    }

    /// Applies per-item font-face preview styling in font picker.
    private func applyFontPreview(to picker: NSPopUpButton) {
        for (index, family) in picker.itemTitles.enumerated() {
            guard let item = picker.item(at: index) else { continue }
            let previewFont = NSFont(name: family, size: 13) ?? NSFont.systemFont(ofSize: 13)
            item.attributedTitle = NSAttributedString(string: family, attributes: [.font: previewFont])
        }
    }

    /// Polls defaults state and live-applies style/content changes.
    private func syncLiveSettingsIfNeeded() {
        let fontName = saverDefaults?.string(forKey: Keys.fontName) ?? ""
        let fontSize = String(format: "%.1f", saverDefaults?.double(forKey: Keys.fontSize) ?? 48)
        let bgMode = saverDefaults?.string(forKey: Keys.backgroundMode) ?? ""
        let bundledBG = saverDefaults?.string(forKey: Keys.bundledBackgroundFileName) ?? ""
        let customBG = saverDefaults?.string(forKey: Keys.customBackgroundFilePath) ?? ""
        let animationStyle = saverDefaults?.string(forKey: Keys.animationStyle) ?? ""
        let baseSeconds = String(format: "%.1f", saverDefaults?.double(forKey: Keys.baseSeconds) ?? 5)
        let showsAttribution = String(saverDefaults?.bool(forKey: Keys.showsAttribution) ?? true)
        let foregroundHash = String((saverDefaults?.data(forKey: Keys.foregroundColorData) ?? Data()).hashValue)
        let backgroundHash = String((saverDefaults?.data(forKey: Keys.backgroundColorData) ?? Data()).hashValue)
        let styleFingerprint = [
            fontName, fontSize, bgMode, bundledBG, customBG,
            animationStyle, baseSeconds, showsAttribution, foregroundHash, backgroundHash
        ].joined(separator: "|")

        let bundledTheme = saverDefaults?.string(forKey: Keys.bundledQuoteFileName) ?? ""
        let customQuote = saverDefaults?.string(forKey: Keys.customQuoteFilePath) ?? ""
        let quoteSourceFingerprint = [bundledTheme, customQuote].joined(separator: "|")

        if lastQuoteSourceFingerprint != quoteSourceFingerprint {
            lastQuoteSourceFingerprint = quoteSourceFingerprint
            loadQuotes()
            showNextQuote(animated: false)
            scheduleNext()
            return
        }

        if lastStyleFingerprint != styleFingerprint {
            lastStyleFingerprint = styleFingerprint
            applyBackground()
            if let currentQuote {
                transitionToQuote(currentQuote, animated: false)
            }
            scheduleNext()
        }
    }

    /// Runs configured quote entrance animation.
    private func animateQuoteEntrance(style: AnimationStyle) {
        let resolvedStyle: AnimationStyle
        if style == .randomTransition {
            let pool = AnimationStyle.allCases.filter { $0 != .randomTransition }
            resolvedStyle = pool.randomElement() ?? .fade
        } else {
            resolvedStyle = style
        }

        switch resolvedStyle {
        case .fade:
            animateFadeIn()
        case .dropDown:
            animateWithTransform(transform: CATransform3DMakeTranslation(0, 110, 0), duration: 0.9)
        case .slide:
            let direction: CGFloat = Bool.random() ? -1 : 1
            let offset = max(220.0, bounds.width * 0.4) * direction
            animateWithTransform(transform: CATransform3DMakeTranslation(offset, 0, 0), duration: 0.85)
        case .materialize:
            animateWithTransform(transform: CATransform3DMakeScale(0.2, 0.2, 1), duration: 0.8)
        case .genie:
            animateGenieIn()
        case .flagWave:
            animateFlagWaveIn()
        case .randomTransition:
            animateFadeIn()
        }
    }

    /// Simple fade-in entrance animation.
    private func animateFadeIn() {
        quoteLabel.layer?.transform = CATransform3DIdentity
        quoteLabel.alphaValue = 0
        attributionLabel.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.75
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            quoteLabel.animator().alphaValue = 1
            attributionLabel.animator().alphaValue = 1
        }
    }

    /// Generic transform + alpha entrance helper.
    private func animateWithTransform(transform: CATransform3D, duration: TimeInterval) {
        quoteLabel.alphaValue = 0
        attributionLabel.alphaValue = 0
        quoteLabel.layer?.transform = CATransform3DIdentity

        if let layer = quoteLabel.layer {
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.fromValue = transform
            transformAnimation.toValue = CATransform3DIdentity
            transformAnimation.duration = duration
            transformAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(transformAnimation, forKey: "quoteTransformIn")
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            quoteLabel.animator().alphaValue = 1
            attributionLabel.animator().alphaValue = 1
        }
    }

    /// Genie-style entrance from random direction.
    private func animateGenieIn() {
        let horizontal = Bool.random() ? -1.0 : 1.0
        let vertical = Bool.random() ? -1.0 : 1.0
        let xOffset = max(250.0, bounds.width * 0.45) * horizontal
        let yOffset = max(160.0, bounds.height * 0.32) * vertical
        var start = CATransform3DIdentity
        start = CATransform3DTranslate(start, xOffset, yOffset, 0)
        start = CATransform3DScale(start, 0.06, 0.24, 1)
        start = CATransform3DRotate(start, CGFloat.pi / 14 * horizontal, 0, 0, 1)
        animateWithTransform(transform: start, duration: 0.95)
    }

    /// Flag-wave style entrance animation.
    private func animateFlagWaveIn() {
        quoteLabel.alphaValue = 0
        attributionLabel.alphaValue = 0
        quoteLabel.layer?.transform = CATransform3DMakeScale(0.85, 0.85, 1)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.38
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            quoteLabel.animator().alphaValue = 1
            attributionLabel.animator().alphaValue = 1
        }

        guard let layer = quoteLabel.layer else { return }
        let wave = CAKeyframeAnimation(keyPath: "transform")
        wave.values = [
            CATransform3DMakeScale(0.85, 0.85, 1),
            CATransform3DConcat(CATransform3DMakeTranslation(20, 0, 0), CATransform3DMakeScale(1.04, 0.92, 1)),
            CATransform3DConcat(CATransform3DMakeTranslation(-16, 0, 0), CATransform3DMakeScale(0.97, 1.06, 1)),
            CATransform3DConcat(CATransform3DMakeTranslation(12, 0, 0), CATransform3DMakeScale(1.02, 0.96, 1)),
            CATransform3DConcat(CATransform3DMakeTranslation(-8, 0, 0), CATransform3DMakeScale(0.99, 1.03, 1)),
            CATransform3DIdentity
        ]
        wave.keyTimes = [0.0, 0.22, 0.44, 0.66, 0.84, 1.0] as [NSNumber]
        wave.duration = 1.05
        wave.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(wave, forKey: "flagWave")
        layer.transform = CATransform3DIdentity
    }
}
