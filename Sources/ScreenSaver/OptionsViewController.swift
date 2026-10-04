import AppKit
import UniformTypeIdentifiers

/// Root options container (tabbed) for standalone runtime settings.
@MainActor
final class OptionsViewController: NSTabViewController {
    /// Initializes tabs after view load.
    override func viewDidLoad() {
        super.viewDidLoad()
        tabStyle = .toolbar
        let display = DisplayOptionsViewController()
        display.title = "Display"
        addChild(display)
        _ = display.view
        preferredContentSize = display.preferredContentSize
    }
}

/// Display/settings tab for fonts, colors, backgrounds, content source, timing, and animation.
@MainActor
final class DisplayOptionsViewController: NSViewController {
    // Design-time outlets for `DisplayOptionsView.xib`. The standalone app
    // still uses the programmatic layout below; these give Interface Builder
    // a fully connectable surface while the XIB is being shaped visually.
    @IBOutlet private weak var xibFontPicker: NSPopUpButton?
    @IBOutlet private weak var xibBackgroundColorWell: NSColorWell?
    @IBOutlet private weak var xibFontColorWell: NSColorWell?
    @IBOutlet private weak var xibFontSizeSlider: NSSlider?
    @IBOutlet private weak var xibFontSizeValueLabel: NSTextField?
    @IBOutlet private weak var xibUseProposedFontCheckbox: NSButton?
    @IBOutlet private weak var xibBackgroundModePicker: NSPopUpButton?
    @IBOutlet private weak var xibBundledBackgroundPicker: NSPopUpButton?
    @IBOutlet private weak var xibCustomBackgroundPathLabel: NSTextField?
    @IBOutlet private weak var xibChooseBackgroundButton: NSButton?
    @IBOutlet private weak var xibClearBackgroundButton: NSButton?
    @IBOutlet private weak var xibQuoteThemePicker: NSPopUpButton?
    @IBOutlet private weak var xibQuoteFilePathLabel: NSTextField?
    @IBOutlet private weak var xibChooseXMLButton: NSButton?
    @IBOutlet private weak var xibUseBundledButton: NSButton?
    @IBOutlet private weak var xibAnimationStylePicker: NSPopUpButton?
    @IBOutlet private weak var xibBaseTimeSlider: NSSlider?
    @IBOutlet private weak var xibBaseTimeValueLabel: NSTextField?
    @IBOutlet private weak var xibShowAttributionCheckbox: NSButton?

    private let usesXIBLayout: Bool

    private var activeFontPicker: NSPopUpButton { xibFontPicker ?? fontPicker }
    private var activeBackgroundColorWell: NSColorWell { xibBackgroundColorWell ?? colorWell }
    private var activeFontColorWell: NSColorWell { xibFontColorWell ?? foregroundWell }
    private var activeFontSizeSlider: NSSlider { xibFontSizeSlider ?? fontSizeSlider }
    private var activeFontSizeValueLabel: NSTextField { xibFontSizeValueLabel ?? fontSizeValueLabel }
    private var activeUseProposedFontSwitch: NSSwitch { useProposedFontSwitch }
    private var activeBackgroundModePicker: NSPopUpButton { xibBackgroundModePicker ?? backgroundModePicker }
    private var activeBundledBackgroundPicker: NSPopUpButton { xibBundledBackgroundPicker ?? bundledBackgroundPicker }
    private var activeCustomBackgroundPathLabel: NSTextField { xibCustomBackgroundPathLabel ?? customBackgroundPathLabel }
    private var activeChooseBackgroundButton: NSButton { xibChooseBackgroundButton ?? chooseBackgroundButton }
    private var activeClearBackgroundButton: NSButton { xibClearBackgroundButton ?? clearBackgroundButton }
    private var activeQuoteThemePicker: NSPopUpButton { xibQuoteThemePicker ?? quoteThemePicker }
    private var activeQuoteFilePathLabel: NSTextField { xibQuoteFilePathLabel ?? quoteFilePathLabel }
    private var activeChooseXMLButton: NSButton { xibChooseXMLButton ?? chooseXMLButton }
    private var activeUseBundledButton: NSButton { xibUseBundledButton ?? useBundledButton }
    private var activeAnimationStylePicker: NSPopUpButton { xibAnimationStylePicker ?? animationStylePicker }
    private var activeBaseTimeSlider: NSSlider { xibBaseTimeSlider ?? baseTimeSlider }
    private var activeBaseTimeValueLabel: NSTextField { xibBaseTimeValueLabel ?? baseTimeValueLabel }
    private var activeShowAttributionCheckbox: NSButton { xibShowAttributionCheckbox ?? showAttributionCheckbox }

    init() {
        let hasNib = Bundle.module.url(forResource: "DisplayOptionsView", withExtension: "nib") != nil
        usesXIBLayout = hasNib
        super.init(nibName: hasNib ? NSNib.Name("DisplayOptionsView") : nil, bundle: hasNib ? .module : nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private let fontLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Font")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let fontPicker: NSPopUpButton = {
        let picker = NSPopUpButton()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let useProposedFontLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Use Proposed Font?")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let proposedFontNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "No proposed font")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let useProposedFontSwitch: NSSwitch = {
        let control = NSSwitch()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let colorLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Background Color")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let backgroundModeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Background Mode")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let backgroundModePicker: NSPopUpButton = {
        let picker = NSPopUpButton()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let bundledBackgroundLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Bundled Background")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bundledBackgroundPicker: NSPopUpButton = {
        let picker = NSPopUpButton()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let customBackgroundPathLabel: NSTextField = {
        let label = NSTextField(labelWithString: "No custom image selected")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let chooseBackgroundButton: NSButton = {
        let button = NSButton(title: "Choose Image...", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let clearBackgroundButton: NSButton = {
        let button = NSButton(title: "Clear Custom", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let colorWell: NSColorWell = {
        let well = NSColorWell()
        well.translatesAutoresizingMaskIntoConstraints = false
        return well
    }()

    private let foregroundLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Font Color")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let foregroundWell: NSColorWell = {
        let well = NSColorWell()
        well.translatesAutoresizingMaskIntoConstraints = false
        return well
    }()

    private let fontSizeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Font Size")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let fontSizeSlider: NSSlider = {
        let slider = NSSlider(value: 48, minValue: 18, maxValue: 140, target: nil, action: nil)
        slider.numberOfTickMarks = 0
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let fontSizeValueLabel: NSTextField = {
        let label = NSTextField(labelWithString: "48")
        label.alignment = .right
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let animationStyleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Animation Style")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let animationStylePicker: NSPopUpButton = {
        let picker = NSPopUpButton()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let baseTimeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Base Quote Time (sec)")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let baseTimeSlider: NSSlider = {
        let slider = NSSlider(value: 5, minValue: 3, maxValue: 20, target: nil, action: nil)
        slider.numberOfTickMarks = 0
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let baseTimeValueLabel: NSTextField = {
        let label = NSTextField(labelWithString: "5.0")
        label.alignment = .right
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let showAttributionCheckbox: NSButton = {
        let button = NSButton(checkboxWithTitle: "Show Attribution (bottom-right)", target: nil, action: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let quoteFileLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Quote XML File")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let quoteThemeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Theme")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let quoteThemePicker: NSPopUpButton = {
        let picker = NSPopUpButton()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let quoteFilePathLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Using bundled quotes.xml")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let chooseXMLButton: NSButton = {
        let button = NSButton(title: "Choose XML...", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let useBundledButton: NSButton = {
        let button = NSButton(title: "Use Bundled", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Builds root view container.
    override func loadView() {
        if usesXIBLayout {
            super.loadView()
            return
        }

        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false
        view = root
    }

    /// Configures controls and layout constraints.
    override func viewDidLoad() {
        super.viewDidLoad()
        installProposedFontControlSurfaceIfNeeded()
        configureControls()
        if !usesXIBLayout {
            configureLayout()
            preferredContentSize = NSSize(width: 500, height: 760)
        } else {
            let fittedSize = view.fittingSize
            let frameSize = view.frame.size
            preferredContentSize = NSSize(
                width: max(fittedSize.width, frameSize.width),
                height: max(fittedSize.height, frameSize.height)
            )
        }
    }

    /// Initializes control values from current `AppSettings` and installs action handlers.
    private func configureControls() {
        let fontPicker = activeFontPicker
        let backgroundModePicker = activeBackgroundModePicker
        let bundledBackgroundPicker = activeBundledBackgroundPicker
        let backgroundColorWell = activeBackgroundColorWell
        let fontColorWell = activeFontColorWell
        let fontSizeSlider = activeFontSizeSlider
        let fontSizeValueLabel = activeFontSizeValueLabel
        let useProposedFontSwitch = activeUseProposedFontSwitch
        let animationStylePicker = activeAnimationStylePicker
        let baseTimeSlider = activeBaseTimeSlider
        let baseTimeValueLabel = activeBaseTimeValueLabel
        let showAttributionCheckbox = activeShowAttributionCheckbox
        let quoteThemePicker = activeQuoteThemePicker
        let chooseXMLButton = activeChooseXMLButton
        let useBundledButton = activeUseBundledButton
        let chooseBackgroundButton = activeChooseBackgroundButton
        let clearBackgroundButton = activeClearBackgroundButton

        let families = NSFontManager.shared.availableFontFamilies.sorted()
        fontPicker.removeAllItems()
        fontPicker.addItems(withTitles: families)
        applyFontPreview(to: families)

        let selectedFont = AppSettings.shared.fontName
        if let itemIndex = families.firstIndex(of: selectedFont) {
            fontPicker.selectItem(at: itemIndex)
        } else if let papyrusIndex = families.firstIndex(of: "Papyrus") {
            fontPicker.selectItem(at: papyrusIndex)
        }

        backgroundModePicker.removeAllItems()
        backgroundModePicker.addItems(withTitles: ["Solid Color", "Bundled Image", "Custom Image"])
        switch AppSettings.shared.backgroundMode {
        case .solid: backgroundModePicker.selectItem(at: 0)
        case .bundledImage: backgroundModePicker.selectItem(at: 1)
        case .customImage: backgroundModePicker.selectItem(at: 2)
        }

        bundledBackgroundPicker.removeAllItems()
        bundledBackgroundPicker.addItems(withTitles: AppSettings.bundledBackgrounds.map(\.title))
        if let idx = AppSettings.bundledBackgrounds.firstIndex(where: { $0.fileName == AppSettings.shared.bundledBackgroundFileName }) {
            bundledBackgroundPicker.selectItem(at: idx)
        }

        backgroundColorWell.color = AppSettings.shared.backgroundColor
        fontColorWell.color = AppSettings.shared.foregroundColor
        fontSizeSlider.doubleValue = Double(AppSettings.shared.fontSize)
        fontSizeValueLabel.stringValue = "\(Int(AppSettings.shared.fontSize))"
        useProposedFontSwitch.state = AppSettings.shared.useProposedFont ? .on : .off
        animationStylePicker.removeAllItems()
        animationStylePicker.addItems(withTitles: AppSettings.AnimationStyle.allCases.map(\.title))
        if let styleIndex = AppSettings.AnimationStyle.allCases.firstIndex(of: AppSettings.shared.animationStyle) {
            animationStylePicker.selectItem(at: styleIndex)
        }
        baseTimeSlider.doubleValue = AppSettings.shared.baseQuoteSeconds
        baseTimeValueLabel.stringValue = String(format: "%.1f", AppSettings.shared.baseQuoteSeconds)
        showAttributionCheckbox.state = AppSettings.shared.showsAttribution ? .on : .off
        quoteThemePicker.removeAllItems()
        quoteThemePicker.addItems(withTitles: AppSettings.bundledThemes.map(\.title))
        if let selectedIndex = AppSettings.bundledThemes.firstIndex(where: { $0.fileName == AppSettings.shared.bundledQuoteFileName }) {
            quoteThemePicker.selectItem(at: selectedIndex)
        }
        refreshQuoteFilePathLabel()

        fontPicker.target = self
        fontPicker.action = #selector(fontDidChange(_:))
        backgroundColorWell.target = self
        backgroundColorWell.action = #selector(colorDidChange(_:))
        fontColorWell.target = self
        fontColorWell.action = #selector(foregroundDidChange(_:))
        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeDidChange(_:))
        useProposedFontSwitch.target = self
        useProposedFontSwitch.action = #selector(useProposedFontDidChange(_:))
        animationStylePicker.target = self
        animationStylePicker.action = #selector(animationStyleDidChange(_:))
        baseTimeSlider.target = self
        baseTimeSlider.action = #selector(baseTimeDidChange(_:))
        showAttributionCheckbox.target = self
        showAttributionCheckbox.action = #selector(showAttributionDidChange(_:))
        chooseXMLButton.target = self
        chooseXMLButton.action = #selector(chooseXMLFile(_:))
        useBundledButton.target = self
        useBundledButton.action = #selector(useBundledQuotes(_:))
        quoteThemePicker.target = self
        quoteThemePicker.action = #selector(themeDidChange(_:))
        backgroundModePicker.target = self
        backgroundModePicker.action = #selector(backgroundModeDidChange(_:))
        bundledBackgroundPicker.target = self
        bundledBackgroundPicker.action = #selector(bundledBackgroundDidChange(_:))
        chooseBackgroundButton.target = self
        chooseBackgroundButton.action = #selector(chooseBackgroundImage(_:))
        clearBackgroundButton.target = self
        clearBackgroundButton.action = #selector(clearCustomBackground(_:))
        refreshBackgroundPathLabel()
        refreshBackgroundControlState()
        refreshProposedFontNameLabel()
    }

    /// Replaces the XIB checkbox-shaped button with a label, font name, and switch.
    private func installProposedFontControlSurfaceIfNeeded() {
        guard usesXIBLayout, let anchor = xibUseProposedFontCheckbox else { return }
        anchor.isHidden = true
        anchor.isEnabled = false

        let switchWidth: CGFloat = 52
        let rowHeight: CGFloat = 24
        let leftX: CGFloat = 38
        let switchX = view.bounds.width - switchWidth - 42
        let rowY = anchor.frame.midY - (rowHeight / 2)

        useProposedFontLabel.translatesAutoresizingMaskIntoConstraints = true
        proposedFontNameLabel.translatesAutoresizingMaskIntoConstraints = true
        useProposedFontSwitch.translatesAutoresizingMaskIntoConstraints = true

        useProposedFontLabel.frame = NSRect(x: leftX, y: rowY + 2, width: 126, height: 20)
        proposedFontNameLabel.frame = NSRect(
            x: useProposedFontLabel.frame.maxX + 8,
            y: rowY + 2,
            width: max(80, switchX - useProposedFontLabel.frame.maxX - 18),
            height: 20
        )
        useProposedFontSwitch.frame = NSRect(x: switchX, y: rowY, width: switchWidth, height: rowHeight)

        if useProposedFontLabel.superview == nil {
            view.addSubview(useProposedFontLabel)
        }
        if proposedFontNameLabel.superview == nil {
            view.addSubview(proposedFontNameLabel)
        }
        if useProposedFontSwitch.superview == nil {
            view.addSubview(useProposedFontSwitch)
        }
    }

    /// Applies live font-face preview to font picker rows.
    /// - Parameter families: Ordered list of font family names.
    private func applyFontPreview(to families: [String]) {
        let fontPicker = activeFontPicker
        for (index, family) in families.enumerated() {
            guard let item = fontPicker.item(at: index) else { continue }
            let previewFont = NSFont(name: family, size: 13) ?? NSFont.systemFont(ofSize: 13)
            item.attributedTitle = NSAttributedString(
                string: family,
                attributes: [.font: previewFont]
            )
        }
    }

    /// Lays out all display tab controls.
    private func configureLayout() {
        colorWell.widthAnchor.constraint(equalToConstant: 72).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 30).isActive = true
        foregroundWell.widthAnchor.constraint(equalToConstant: 72).isActive = true
        foregroundWell.heightAnchor.constraint(equalToConstant: 30).isActive = true
        fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true
        baseTimeValueLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let rootStack = makeStack(orientation: .vertical, spacing: 16)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        let appearanceStack = makeStack(orientation: .vertical, spacing: 12)
        appearanceStack.addArrangedSubview(makeFieldStack(label: fontLabel, control: fontPicker))
        appearanceStack.addArrangedSubview(makeProposedFontRow())
        appearanceStack.addArrangedSubview(makeSliderFieldStack(label: fontSizeLabel, slider: fontSizeSlider, valueLabel: fontSizeValueLabel))
        appearanceStack.addArrangedSubview(
            makeStack(
                orientation: .horizontal,
                spacing: 18,
                views: [
                    makeFieldStack(label: colorLabel, control: colorWell),
                    makeFieldStack(label: foregroundLabel, control: foregroundWell)
                ]
            )
        )

        let backgroundButtonsRow = makeStack(
            orientation: .horizontal,
            spacing: 10,
            views: [chooseBackgroundButton, clearBackgroundButton]
        )
        backgroundButtonsRow.alignment = .centerY

        let backgroundStack = makeStack(orientation: .vertical, spacing: 12)
        backgroundStack.addArrangedSubview(makeFieldStack(label: backgroundModeLabel, control: backgroundModePicker))
        backgroundStack.addArrangedSubview(makeFieldStack(label: bundledBackgroundLabel, control: bundledBackgroundPicker))
        backgroundStack.addArrangedSubview(customBackgroundPathLabel)
        backgroundStack.addArrangedSubview(backgroundButtonsRow)

        let quotesButtonsRow = makeStack(
            orientation: .horizontal,
            spacing: 10,
            views: [chooseXMLButton, useBundledButton]
        )
        quotesButtonsRow.alignment = .centerY

        let quotesStack = makeStack(orientation: .vertical, spacing: 12)
        quotesStack.addArrangedSubview(makeFieldStack(label: quoteThemeLabel, control: quoteThemePicker))
        quotesStack.addArrangedSubview(makeFieldStack(label: quoteFileLabel, control: quoteFilePathLabel))
        quotesStack.addArrangedSubview(quotesButtonsRow)

        let playbackStack = makeStack(orientation: .vertical, spacing: 12)
        playbackStack.addArrangedSubview(makeFieldStack(label: animationStyleLabel, control: animationStylePicker))
        playbackStack.addArrangedSubview(makeSliderFieldStack(label: baseTimeLabel, slider: baseTimeSlider, valueLabel: baseTimeValueLabel))
        playbackStack.addArrangedSubview(showAttributionCheckbox)

        let appearanceSection = makeSectionView(title: "Appearance", content: appearanceStack)
        let backgroundSection = makeSectionView(title: "Background", content: backgroundStack)
        let quoteSourceSection = makeSectionView(title: "Quote Source", content: quotesStack)
        let playbackSection = makeSectionView(title: "Playback", content: playbackStack)

        rootStack.addArrangedSubview(appearanceSection)
        rootStack.addArrangedSubview(backgroundSection)
        rootStack.addArrangedSubview(quoteSourceSection)
        rootStack.addArrangedSubview(playbackSection)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 500),
            view.heightAnchor.constraint(equalToConstant: 760),

            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20),

            appearanceSection.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            backgroundSection.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            quoteSourceSection.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            playbackSection.widthAnchor.constraint(equalTo: rootStack.widthAnchor)
        ])
    }

    /// Builds a bordered section container with a title and padded content.
    private func makeSectionView(title: String, content: NSView) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 8
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor.separatorColor.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),

            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            content.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        return container
    }

    /// Builds a standard label/control field stack.
    private func makeFieldStack(label: NSTextField, control: NSView) -> NSStackView {
        makeStack(orientation: .vertical, spacing: 8, views: [label, control])
    }

    /// Builds a slider row with a trailing numeric value label.
    private func makeSliderFieldStack(label: NSTextField, slider: NSSlider, valueLabel: NSTextField) -> NSStackView {
        let row = makeStack(orientation: .horizontal, spacing: 10, views: [slider, valueLabel])
        row.alignment = .centerY
        return makeStack(orientation: .vertical, spacing: 8, views: [label, row])
    }

    /// Builds the proposed-font row used by the programmatic fallback layout.
    private func makeProposedFontRow() -> NSStackView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        proposedFontNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        proposedFontNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = makeStack(
            orientation: .horizontal,
            spacing: 8,
            views: [useProposedFontLabel, proposedFontNameLabel, spacer, useProposedFontSwitch]
        )
        row.alignment = .centerY
        return row
    }

    /// Builds a configured stack view with optional arranged subviews.
    private func makeStack(orientation: NSUserInterfaceLayoutOrientation, spacing: CGFloat, views: [NSView] = []) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = orientation
        stack.spacing = spacing
        stack.alignment = (orientation == .vertical) ? .width : .top
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    /// Font picker handler.
    @objc private func fontDidChange(_ sender: NSPopUpButton) {
        guard let name = sender.selectedItem?.title else { return }
        AppSettings.shared.updateFontName(name)
    }

    /// Background mode picker handler.
    @objc private func backgroundModeDidChange(_ sender: NSPopUpButton) {
        let mode: AppSettings.BackgroundMode
        switch sender.indexOfSelectedItem {
        case 1: mode = .bundledImage
        case 2: mode = .customImage
        default: mode = .solid
        }
        AppSettings.shared.updateBackgroundMode(mode)
        refreshBackgroundControlState()
    }

    /// Bundled background picker handler.
    @objc private func bundledBackgroundDidChange(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < AppSettings.bundledBackgrounds.count else { return }
        let selected = AppSettings.bundledBackgrounds[idx]
        AppSettings.shared.updateBundledBackgroundFileName(selected.fileName)
        if AppSettings.shared.backgroundMode != .bundledImage {
            AppSettings.shared.updateBackgroundMode(.bundledImage)
            activeBackgroundModePicker.selectItem(at: 1)
            refreshBackgroundControlState()
        }
    }

    /// Opens file picker and stores selected custom background image.
    @objc private func chooseBackgroundImage(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .gif, .bmp]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Background"
        panel.message = "Choose an image file (jpg/png/bmp/gif)."

        if panel.runModal() == .OK, let url = panel.url {
            AppSettings.shared.updateCustomBackgroundFilePath(url.path)
            AppSettings.shared.updateBackgroundMode(.customImage)
            activeBackgroundModePicker.selectItem(at: 2)
            refreshBackgroundPathLabel()
            refreshBackgroundControlState()
        }
    }

    /// Clears selected custom background image path.
    @objc private func clearCustomBackground(_ sender: NSButton) {
        AppSettings.shared.updateCustomBackgroundFilePath(nil)
        if AppSettings.shared.backgroundMode == .customImage {
            AppSettings.shared.updateBackgroundMode(.solid)
            activeBackgroundModePicker.selectItem(at: 0)
        }
        refreshBackgroundPathLabel()
        refreshBackgroundControlState()
    }

    /// Solid background color picker handler.
    @objc private func colorDidChange(_ sender: NSColorWell) {
        AppSettings.shared.updateBackgroundColor(sender.color)
    }

    /// Foreground text color picker handler.
    @objc private func foregroundDidChange(_ sender: NSColorWell) {
        AppSettings.shared.updateForegroundColor(sender.color)
    }

    /// Font size slider handler.
    @objc private func fontSizeDidChange(_ sender: NSSlider) {
        let rounded = CGFloat(Int(sender.doubleValue.rounded()))
        sender.doubleValue = Double(rounded)
        activeFontSizeValueLabel.stringValue = "\(Int(rounded))"
        AppSettings.shared.updateFontSize(rounded)
    }

    /// Proposed XML font toggle handler.
    @objc private func useProposedFontDidChange(_ sender: NSControl) {
        AppSettings.shared.updateUseProposedFont(sender.integerValue == NSControl.StateValue.on.rawValue)
    }

    /// Animation style picker handler.
    @objc private func animationStyleDidChange(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard index >= 0, index < AppSettings.AnimationStyle.allCases.count else { return }
        let selected = AppSettings.AnimationStyle.allCases[index]
        AppSettings.shared.updateAnimationStyle(selected)
    }

    /// Base display-time slider handler.
    @objc private func baseTimeDidChange(_ sender: NSSlider) {
        let rounded = (sender.doubleValue * 2).rounded() / 2
        sender.doubleValue = rounded
        activeBaseTimeValueLabel.stringValue = String(format: "%.1f", rounded)
        AppSettings.shared.updateBaseQuoteSeconds(rounded)
    }

    /// Attribution visibility toggle handler.
    @objc private func showAttributionDidChange(_ sender: NSButton) {
        AppSettings.shared.updateShowsAttribution(sender.state == .on)
    }

    /// Opens file picker and stores selected custom quote XML.
    @objc private func chooseXMLFile(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Quote File"
        panel.message = "Choose an XML file with <Quote>/<author> pairs."

        if panel.runModal() == .OK, let url = panel.url {
            AppSettings.shared.updateCustomQuoteFilePath(url.path)
            refreshQuoteFilePathLabel()
            refreshProposedFontNameLabel()
        }
    }

    /// Switches quote source back to bundled XML.
    @objc private func useBundledQuotes(_ sender: NSButton) {
        AppSettings.shared.updateCustomQuoteFilePath(nil)
        refreshQuoteFilePathLabel()
        refreshProposedFontNameLabel()
    }

    /// Theme picker handler for bundled quote libraries.
    @objc private func themeDidChange(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard index >= 0, index < AppSettings.bundledThemes.count else { return }
        let selected = AppSettings.bundledThemes[index]
        AppSettings.shared.updateBundledQuoteFileName(selected.fileName)
        if AppSettings.shared.customQuoteFilePath != nil {
            AppSettings.shared.updateCustomQuoteFilePath(nil)
        }
        refreshQuoteFilePathLabel()
        refreshProposedFontNameLabel()
    }

    /// Refreshes quote source path label based on custom/bundled selection.
    private func refreshQuoteFilePathLabel() {
        if let path = AppSettings.shared.customQuoteFilePath, !path.isEmpty {
            activeQuoteFilePathLabel.stringValue = path
        } else {
            let file = AppSettings.shared.bundledQuoteFileName
            activeQuoteFilePathLabel.stringValue = "Using bundled \(file)"
        }
    }

    /// Refreshes the grey proposed font label from the currently selected quote source.
    private func refreshProposedFontNameLabel() {
        proposedFontNameLabel.stringValue = currentProposedFontName()
    }

    /// Returns the first non-empty XML font suggestion for the active source.
    private func currentProposedFontName() -> String {
        let quotes: [Quote]
        if let path = AppSettings.shared.customQuoteFilePath, !path.isEmpty {
            quotes = (try? QuoteRepository.loadQuotes(from: URL(fileURLWithPath: path))) ?? []
        } else {
            quotes = (try? QuoteRepository.loadBundledQuotes(named: AppSettings.shared.bundledQuoteFileName)) ?? []
        }

        return quotes
            .compactMap { $0.font?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
            ?? "No proposed font"
    }

    /// Refreshes custom background path label.
    private func refreshBackgroundPathLabel() {
        if let path = AppSettings.shared.customBackgroundFilePath, !path.isEmpty {
            activeCustomBackgroundPathLabel.stringValue = path
        } else {
            activeCustomBackgroundPathLabel.stringValue = "No custom image selected"
        }
    }

    /// Enables/disables background-related controls based on selected mode.
    private func refreshBackgroundControlState() {
        let mode = AppSettings.shared.backgroundMode
        activeBackgroundColorWell.isEnabled = (mode == .solid)
        activeBundledBackgroundPicker.isEnabled = (mode == .bundledImage)
        activeChooseBackgroundButton.isEnabled = true
        activeClearBackgroundButton.isEnabled = (AppSettings.shared.customBackgroundFilePath != nil)
    }
}
