import AppKit
import QuartzCore

/// Primary quote renderer for the standalone runtime.
///
/// Handles:
/// - quote rotation and timing
/// - style/background application from `AppSettings`
/// - animated quote transitions
@MainActor
final class QuoteViewController: NSViewController {
    private var deck = QuoteDeck(quotes: [])
    private var timer: Timer?
    private var currentQuote: Quote?
    private let backgroundImageView = NSImageView()

    private let quoteBlockLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.wantsLayer = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let attributionLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .right
        label.maximumNumberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    /// Builds the root view and base layer.
    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.black.cgColor
        view = root
    }

    /// Configures subviews, loads initial quotes, and starts timer-driven rotation.
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackgroundView()
        configureLayout()
        reloadQuoteDeck()
        applyStyleSettings()
        observeSettings()
        scheduleNextQuoteTimer()
    }

    /// Stops active timers when controller disappears.
    override func viewWillDisappear() {
        super.viewWillDisappear()
        timer?.invalidate()
        timer = nil
    }

    /// Creates the full-frame background image view.
    private func configureBackgroundView() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.imageScaling = .scaleAxesIndependently
        backgroundImageView.animates = true
        backgroundImageView.isHidden = true
        view.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Creates and constrains quote text and attribution labels.
    private func configureLayout() {
        quoteBlockLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        quoteBlockLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        quoteBlockLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.addSubview(quoteBlockLabel)
        view.addSubview(attributionLabel)

        NSLayoutConstraint.activate([
            quoteBlockLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            quoteBlockLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            quoteBlockLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            quoteBlockLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 40),
            quoteBlockLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -40),

            attributionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            attributionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            attributionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 220)
        ])
    }

    /// Schedules the timer for the next quote transition based on current quote length.
    private func scheduleNextQuoteTimer() {
        timer?.invalidate()
        guard let quote = currentQuote else { return }
        let baseSeconds = AppSettings.shared.baseQuoteSeconds
        let nextInterval = quote.recommendedDisplayDuration(baseSeconds: baseSeconds)
        timer = Timer.scheduledTimer(withTimeInterval: nextInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.showNextQuote(animated: true)
                self.scheduleNextQuoteTimer()
            }
        }
    }

    /// Applies all style-related settings to current scene state.
    private func applyStyleSettings() {
        let settings = AppSettings.shared
        applyBackground(settings)
        applyCurrentQuoteText()
    }

    /// Applies current background mode (solid, bundled image, or custom image).
    /// - Parameter settings: Snapshot of current application settings.
    private func applyBackground(_ settings: AppSettings) {
        switch settings.backgroundMode {
        case .solid:
            backgroundImageView.image = nil
            backgroundImageView.isHidden = true
            view.layer?.backgroundColor = settings.backgroundColor.cgColor
        case .bundledImage:
            let image = loadBundledBackgroundImage(fileName: settings.bundledBackgroundFileName)
            if let image {
                backgroundImageView.image = image
                backgroundImageView.isHidden = false
                view.layer?.backgroundColor = NSColor.black.cgColor
            } else {
                backgroundImageView.image = nil
                backgroundImageView.isHidden = true
                view.layer?.backgroundColor = settings.backgroundColor.cgColor
            }
        case .customImage:
            guard let path = settings.customBackgroundFilePath, !path.isEmpty else {
                backgroundImageView.image = nil
                backgroundImageView.isHidden = true
                view.layer?.backgroundColor = settings.backgroundColor.cgColor
                return
            }
            let expandedPath = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            if let image = NSImage(contentsOf: url) {
                backgroundImageView.image = image
                backgroundImageView.isHidden = false
                view.layer?.backgroundColor = NSColor.black.cgColor
            } else {
                backgroundImageView.image = nil
                backgroundImageView.isHidden = true
                view.layer?.backgroundColor = settings.backgroundColor.cgColor
            }
        }
    }

    /// Loads a bundled background image from target resources.
    /// - Parameter fileName: Relative bundled path (e.g. `images/old-parchment.png`).
    /// - Returns: Decoded image or `nil` if not found/readable.
    private func loadBundledBackgroundImage(fileName: String) -> NSImage? {
        let normalized = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let fileURL = URL(fileURLWithPath: normalized)
        let name = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var subdirectory = fileURL.deletingLastPathComponent().path
        if subdirectory == "." {
            subdirectory = ""
        }
        if subdirectory.hasPrefix("/") {
            subdirectory.removeFirst()
        }
        let lookupSubdirectory = subdirectory.isEmpty ? nil : subdirectory

        if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: lookupSubdirectory),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let directURL = Bundle.module.url(forResource: normalized, withExtension: nil),
           let image = NSImage(contentsOf: directURL) {
            return image
        }

        if let flattenedURL = Bundle.module.url(forResource: name, withExtension: ext),
           let image = NSImage(contentsOf: flattenedURL) {
            return image
        }

        return nil
    }

    /// Subscribes to style/content notifications from `AppSettings`.
    private func observeSettings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(styleSettingsDidChange(_:)),
            name: .styleSettingsDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(quoteSourceDidChange(_:)),
            name: .quoteSourceDidChange,
            object: nil
        )
    }

    /// Notification handler for visual-style changes.
    @objc private func styleSettingsDidChange(_ notification: Notification) {
        applyStyleSettings()
        scheduleNextQuoteTimer()
    }

    /// Notification handler for quote-source changes.
    @objc private func quoteSourceDidChange(_ notification: Notification) {
        reloadQuoteDeck()
        scheduleNextQuoteTimer()
    }

    /// Rebuilds the quote deck from current source settings.
    private func reloadQuoteDeck() {
        let settings = AppSettings.shared
        deck = QuoteDeck(
            quotes: QuoteDeck.initialQuotes(
                customFilePath: settings.customQuoteFilePath,
                bundledFileName: settings.bundledQuoteFileName
            )
        )
        currentQuote = nil
        showNextQuote(animated: false)
        scheduleNextQuoteTimer()
    }

    /// Re-renders the current quote and attribution labels with live style values.
    private func applyCurrentQuoteText() {
        guard let quote = currentQuote else { return }
        let settings = AppSettings.shared
        let quoteSize = settings.fontSize
        let authorSize = max(14, round(quoteSize * 0.58))
        let resolvedFontName = quote.preferredFontName(
            fallback: settings.fontName,
            useProposedFont: settings.useProposedFont
        )
        let quoteFont =
            NSFont(name: resolvedFontName, size: quoteSize)
            ?? NSFontManager.shared.font(withFamily: resolvedFontName, traits: [], weight: 5, size: quoteSize)
            ?? NSFont.systemFont(ofSize: quoteSize, weight: .medium)
        let authorFont =
            NSFont(name: resolvedFontName, size: authorSize)
            ?? NSFontManager.shared.font(withFamily: resolvedFontName, traits: [], weight: 5, size: authorSize)
            ?? NSFont.systemFont(ofSize: authorSize, weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.paragraphSpacing = 14

        let quoteAttributes: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: settings.foregroundColor,
            .paragraphStyle: paragraph
        ]
        let authorAttributes: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: settings.foregroundColor,
            .paragraphStyle: paragraph
        ]

        let text = NSMutableAttributedString(string: quote.body, attributes: quoteAttributes)
        text.append(NSAttributedString(string: "\n- \(quote.author)", attributes: authorAttributes))
        quoteBlockLabel.attributedStringValue = text

        if settings.showsAttribution, let attribution = quote.attribution, !attribution.isEmpty {
            let attributionSize = max(12, round(quoteSize * 0.34))
            let attributionFont =
                NSFont(name: "Arial Narrow", size: attributionSize)
                ?? NSFont(name: "Tahoma", size: attributionSize)
                ?? NSFont.systemFont(ofSize: attributionSize, weight: .regular)
            attributionLabel.font = attributionFont
            attributionLabel.textColor = settings.foregroundColor.withAlphaComponent(0.84)
            attributionLabel.stringValue = attribution
            attributionLabel.isHidden = false
        } else {
            attributionLabel.stringValue = ""
            attributionLabel.isHidden = true
        }
    }

    /// Advances to next quote in randomized deck order.
    /// - Parameter animated: Whether to animate transition.
    private func showNextQuote(animated: Bool) {
        let nextQuote = deck.next()
        transitionToQuote(nextQuote, animated: animated)
    }

    /// Transitions from current quote to a new quote.
    /// - Parameters:
    ///   - quote: Destination quote.
    ///   - animated: `true` to run exit/enter transition.
    private func transitionToQuote(_ quote: Quote, animated: Bool) {
        currentQuote = quote
        guard animated else {
            resetQuoteVisualState()
            applyCurrentQuoteText()
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            quoteBlockLabel.animator().alphaValue = 0.0
            attributionLabel.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyCurrentQuoteText()
                self.animateQuoteEntrance(style: AppSettings.shared.animationStyle)
            }
        }
    }

    /// Resets label alpha/transform values to steady-state defaults.
    private func resetQuoteVisualState() {
        quoteBlockLabel.alphaValue = 1.0
        quoteBlockLabel.layer?.transform = CATransform3DIdentity
        attributionLabel.alphaValue = 1.0
    }

    /// Selects and runs configured entrance animation.
    /// - Parameter style: Preferred style from settings.
    private func animateQuoteEntrance(style: AppSettings.AnimationStyle) {
        let resolvedStyle: AppSettings.AnimationStyle
        if style == .randomTransition {
            let pool = AppSettings.AnimationStyle.allCases.filter { $0 != .randomTransition }
            resolvedStyle = pool.randomElement() ?? .fade
        } else {
            resolvedStyle = style
        }

        switch resolvedStyle {
        case .fade:
            animateFadeIn()
        case .dropDown:
            animateWithTransform(
                transform: CATransform3DMakeTranslation(0, 110, 0),
                duration: 0.9
            )
        case .slide:
            let direction: CGFloat = Bool.random() ? -1 : 1
            let offset = max(220.0, view.bounds.width * 0.4) * direction
            animateWithTransform(
                transform: CATransform3DMakeTranslation(offset, 0, 0),
                duration: 0.85
            )
        case .materialize:
            animateWithTransform(
                transform: CATransform3DMakeScale(0.2, 0.2, 1),
                duration: 0.8
            )
        case .genie:
            animateGenieIn()
        case .flagWave:
            animateFlagWaveIn()
        case .randomTransition:
            animateFadeIn()
        }
    }

    /// Simple cross-fade entrance.
    private func animateFadeIn() {
        quoteBlockLabel.layer?.transform = CATransform3DIdentity
        quoteBlockLabel.alphaValue = 0.0
        attributionLabel.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.8
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            quoteBlockLabel.animator().alphaValue = 1.0
            attributionLabel.animator().alphaValue = 1.0
        }
    }

    /// Generic transform-based entrance helper.
    /// - Parameters:
    ///   - transform: Starting transform.
    ///   - duration: Animation duration.
    private func animateWithTransform(transform: CATransform3D, duration: TimeInterval) {
        quoteBlockLabel.alphaValue = 0.0
        attributionLabel.alphaValue = 0.0
        quoteBlockLabel.layer?.transform = CATransform3DIdentity

        if let layer = quoteBlockLabel.layer {
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
            quoteBlockLabel.animator().alphaValue = 1.0
            attributionLabel.animator().alphaValue = 1.0
        }
    }

    /// Genie-style entry from a random corner.
    private func animateGenieIn() {
        let horizontal = Bool.random() ? -1.0 : 1.0
        let vertical = Bool.random() ? -1.0 : 1.0
        let xOffset = max(250.0, view.bounds.width * 0.45) * horizontal
        let yOffset = max(160.0, view.bounds.height * 0.32) * vertical
        var start = CATransform3DIdentity
        start = CATransform3DTranslate(start, xOffset, yOffset, 0)
        start = CATransform3DScale(start, 0.06, 0.24, 1)
        start = CATransform3DRotate(start, CGFloat.pi / 14 * horizontal, 0, 0, 1)
        animateWithTransform(transform: start, duration: 0.95)
    }

    /// Multi-step flag-wave style entrance animation.
    private func animateFlagWaveIn() {
        quoteBlockLabel.alphaValue = 0.0
        attributionLabel.alphaValue = 0.0
        quoteBlockLabel.layer?.transform = CATransform3DMakeScale(0.85, 0.85, 1)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.38
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            quoteBlockLabel.animator().alphaValue = 1.0
            attributionLabel.animator().alphaValue = 1.0
        }

        guard let layer = quoteBlockLabel.layer else { return }

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
