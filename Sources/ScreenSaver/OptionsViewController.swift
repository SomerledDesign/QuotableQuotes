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
    }
}

/// Display/settings tab for fonts, colors, backgrounds, content source, timing, and animation.
@MainActor
final class DisplayOptionsViewController: NSViewController {
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
        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false
        view = root
    }

    /// Configures controls and layout constraints.
    override func viewDidLoad() {
        super.viewDidLoad()
        configureControls()
        configureLayout()
    }

    /// Initializes control values from current `AppSettings` and installs action handlers.
    private func configureControls() {
        let families = NSFontManager.shared.availableFontFamilies.sorted()
        fontPicker.addItems(withTitles: families)
        applyFontPreview(to: families)

        let selectedFont = AppSettings.shared.fontName
        if let itemIndex = families.firstIndex(of: selectedFont) {
            fontPicker.selectItem(at: itemIndex)
        } else if let papyrusIndex = families.firstIndex(of: "Papyrus") {
            fontPicker.selectItem(at: papyrusIndex)
        }

        backgroundModePicker.addItems(withTitles: ["Solid Color", "Bundled Image", "Custom Image"])
        switch AppSettings.shared.backgroundMode {
        case .solid: backgroundModePicker.selectItem(at: 0)
        case .bundledImage: backgroundModePicker.selectItem(at: 1)
        case .customImage: backgroundModePicker.selectItem(at: 2)
        }

        bundledBackgroundPicker.addItems(withTitles: AppSettings.bundledBackgrounds.map(\.title))
        if let idx = AppSettings.bundledBackgrounds.firstIndex(where: { $0.fileName == AppSettings.shared.bundledBackgroundFileName }) {
            bundledBackgroundPicker.selectItem(at: idx)
        }

        colorWell.color = AppSettings.shared.backgroundColor
        foregroundWell.color = AppSettings.shared.foregroundColor
        fontSizeSlider.doubleValue = Double(AppSettings.shared.fontSize)
        fontSizeValueLabel.stringValue = "\(Int(AppSettings.shared.fontSize))"
        animationStylePicker.addItems(withTitles: AppSettings.AnimationStyle.allCases.map(\.title))
        if let styleIndex = AppSettings.AnimationStyle.allCases.firstIndex(of: AppSettings.shared.animationStyle) {
            animationStylePicker.selectItem(at: styleIndex)
        }
        baseTimeSlider.doubleValue = AppSettings.shared.baseQuoteSeconds
        baseTimeValueLabel.stringValue = String(format: "%.1f", AppSettings.shared.baseQuoteSeconds)
        showAttributionCheckbox.state = AppSettings.shared.showsAttribution ? .on : .off
        quoteThemePicker.addItems(withTitles: AppSettings.bundledThemes.map(\.title))
        if let selectedIndex = AppSettings.bundledThemes.firstIndex(where: { $0.fileName == AppSettings.shared.bundledQuoteFileName }) {
            quoteThemePicker.selectItem(at: selectedIndex)
        }
        refreshQuoteFilePathLabel()

        fontPicker.target = self
        fontPicker.action = #selector(fontDidChange(_:))
        colorWell.target = self
        colorWell.action = #selector(colorDidChange(_:))
        foregroundWell.target = self
        foregroundWell.action = #selector(foregroundDidChange(_:))
        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeDidChange(_:))
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
    }

    /// Applies live font-face preview to font picker rows.
    /// - Parameter families: Ordered list of font family names.
    private func applyFontPreview(to families: [String]) {
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
        view.addSubview(fontLabel)
        view.addSubview(fontPicker)
        view.addSubview(backgroundModeLabel)
        view.addSubview(backgroundModePicker)
        view.addSubview(bundledBackgroundLabel)
        view.addSubview(bundledBackgroundPicker)
        view.addSubview(customBackgroundPathLabel)
        view.addSubview(chooseBackgroundButton)
        view.addSubview(clearBackgroundButton)
        view.addSubview(colorLabel)
        view.addSubview(colorWell)
        view.addSubview(foregroundLabel)
        view.addSubview(foregroundWell)
        view.addSubview(fontSizeLabel)
        view.addSubview(fontSizeSlider)
        view.addSubview(fontSizeValueLabel)
        view.addSubview(animationStyleLabel)
        view.addSubview(animationStylePicker)
        view.addSubview(baseTimeLabel)
        view.addSubview(baseTimeSlider)
        view.addSubview(baseTimeValueLabel)
        view.addSubview(showAttributionCheckbox)
        view.addSubview(quoteFileLabel)
        view.addSubview(quoteThemeLabel)
        view.addSubview(quoteThemePicker)
        view.addSubview(quoteFilePathLabel)
        view.addSubview(chooseXMLButton)
        view.addSubview(useBundledButton)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 440),
            view.heightAnchor.constraint(equalToConstant: 785),

            fontLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            fontLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 26),

            fontPicker.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            fontPicker.topAnchor.constraint(equalTo: fontLabel.bottomAnchor, constant: 10),
            fontPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            backgroundModeLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            backgroundModeLabel.topAnchor.constraint(equalTo: fontPicker.bottomAnchor, constant: 24),

            backgroundModePicker.leadingAnchor.constraint(equalTo: backgroundModeLabel.leadingAnchor),
            backgroundModePicker.topAnchor.constraint(equalTo: backgroundModeLabel.bottomAnchor, constant: 10),
            backgroundModePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            bundledBackgroundLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            bundledBackgroundLabel.topAnchor.constraint(equalTo: backgroundModePicker.bottomAnchor, constant: 16),

            bundledBackgroundPicker.leadingAnchor.constraint(equalTo: bundledBackgroundLabel.leadingAnchor),
            bundledBackgroundPicker.topAnchor.constraint(equalTo: bundledBackgroundLabel.bottomAnchor, constant: 8),
            bundledBackgroundPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            customBackgroundPathLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            customBackgroundPathLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            customBackgroundPathLabel.topAnchor.constraint(equalTo: bundledBackgroundPicker.bottomAnchor, constant: 10),

            chooseBackgroundButton.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            chooseBackgroundButton.topAnchor.constraint(equalTo: customBackgroundPathLabel.bottomAnchor, constant: 10),

            clearBackgroundButton.leadingAnchor.constraint(equalTo: chooseBackgroundButton.trailingAnchor, constant: 10),
            clearBackgroundButton.centerYAnchor.constraint(equalTo: chooseBackgroundButton.centerYAnchor),

            colorLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            colorLabel.topAnchor.constraint(equalTo: chooseBackgroundButton.bottomAnchor, constant: 18),

            colorWell.leadingAnchor.constraint(equalTo: colorLabel.leadingAnchor),
            colorWell.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 10),
            colorWell.widthAnchor.constraint(equalToConstant: 72),
            colorWell.heightAnchor.constraint(equalToConstant: 30),

            foregroundLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            foregroundLabel.topAnchor.constraint(equalTo: colorWell.bottomAnchor, constant: 22),

            foregroundWell.leadingAnchor.constraint(equalTo: foregroundLabel.leadingAnchor),
            foregroundWell.topAnchor.constraint(equalTo: foregroundLabel.bottomAnchor, constant: 10),
            foregroundWell.widthAnchor.constraint(equalToConstant: 72),
            foregroundWell.heightAnchor.constraint(equalToConstant: 30),

            fontSizeLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            fontSizeLabel.topAnchor.constraint(equalTo: foregroundWell.bottomAnchor, constant: 22),

            fontSizeSlider.leadingAnchor.constraint(equalTo: fontSizeLabel.leadingAnchor),
            fontSizeSlider.topAnchor.constraint(equalTo: fontSizeLabel.bottomAnchor, constant: 10),
            fontSizeSlider.trailingAnchor.constraint(equalTo: fontSizeValueLabel.leadingAnchor, constant: -10),

            fontSizeValueLabel.centerYAnchor.constraint(equalTo: fontSizeSlider.centerYAnchor),
            fontSizeValueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 44),

            animationStyleLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            animationStyleLabel.topAnchor.constraint(equalTo: fontSizeSlider.bottomAnchor, constant: 20),

            animationStylePicker.leadingAnchor.constraint(equalTo: animationStyleLabel.leadingAnchor),
            animationStylePicker.topAnchor.constraint(equalTo: animationStyleLabel.bottomAnchor, constant: 10),
            animationStylePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            baseTimeLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            baseTimeLabel.topAnchor.constraint(equalTo: animationStylePicker.bottomAnchor, constant: 20),

            baseTimeSlider.leadingAnchor.constraint(equalTo: baseTimeLabel.leadingAnchor),
            baseTimeSlider.topAnchor.constraint(equalTo: baseTimeLabel.bottomAnchor, constant: 10),
            baseTimeSlider.trailingAnchor.constraint(equalTo: baseTimeValueLabel.leadingAnchor, constant: -10),

            baseTimeValueLabel.centerYAnchor.constraint(equalTo: baseTimeSlider.centerYAnchor),
            baseTimeValueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            baseTimeValueLabel.widthAnchor.constraint(equalToConstant: 44),

            showAttributionCheckbox.leadingAnchor.constraint(equalTo: baseTimeLabel.leadingAnchor),
            showAttributionCheckbox.topAnchor.constraint(equalTo: baseTimeSlider.bottomAnchor, constant: 14),

            quoteFileLabel.leadingAnchor.constraint(equalTo: fontLabel.leadingAnchor),
            quoteFileLabel.topAnchor.constraint(equalTo: showAttributionCheckbox.bottomAnchor, constant: 18),

            quoteThemeLabel.leadingAnchor.constraint(equalTo: quoteFileLabel.leadingAnchor),
            quoteThemeLabel.topAnchor.constraint(equalTo: quoteFileLabel.bottomAnchor, constant: 10),

            quoteThemePicker.leadingAnchor.constraint(equalTo: quoteThemeLabel.leadingAnchor),
            quoteThemePicker.topAnchor.constraint(equalTo: quoteThemeLabel.bottomAnchor, constant: 8),
            quoteThemePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            quoteFilePathLabel.leadingAnchor.constraint(equalTo: quoteFileLabel.leadingAnchor),
            quoteFilePathLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            quoteFilePathLabel.topAnchor.constraint(equalTo: quoteThemePicker.bottomAnchor, constant: 10),

            chooseXMLButton.leadingAnchor.constraint(equalTo: quoteFileLabel.leadingAnchor),
            chooseXMLButton.topAnchor.constraint(equalTo: quoteFilePathLabel.bottomAnchor, constant: 12),

            useBundledButton.leadingAnchor.constraint(equalTo: chooseXMLButton.trailingAnchor, constant: 10),
            useBundledButton.centerYAnchor.constraint(equalTo: chooseXMLButton.centerYAnchor)
        ])
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
            backgroundModePicker.selectItem(at: 1)
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
            backgroundModePicker.selectItem(at: 2)
            refreshBackgroundPathLabel()
            refreshBackgroundControlState()
        }
    }

    /// Clears selected custom background image path.
    @objc private func clearCustomBackground(_ sender: NSButton) {
        AppSettings.shared.updateCustomBackgroundFilePath(nil)
        if AppSettings.shared.backgroundMode == .customImage {
            AppSettings.shared.updateBackgroundMode(.solid)
            backgroundModePicker.selectItem(at: 0)
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
        fontSizeValueLabel.stringValue = "\(Int(rounded))"
        AppSettings.shared.updateFontSize(rounded)
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
        baseTimeValueLabel.stringValue = String(format: "%.1f", rounded)
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
        }
    }

    /// Switches quote source back to bundled XML.
    @objc private func useBundledQuotes(_ sender: NSButton) {
        AppSettings.shared.updateCustomQuoteFilePath(nil)
        refreshQuoteFilePathLabel()
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
    }

    /// Refreshes quote source path label based on custom/bundled selection.
    private func refreshQuoteFilePathLabel() {
        if let path = AppSettings.shared.customQuoteFilePath, !path.isEmpty {
            quoteFilePathLabel.stringValue = path
        } else {
            let file = AppSettings.shared.bundledQuoteFileName
            quoteFilePathLabel.stringValue = "Using bundled \(file)"
        }
    }

    /// Refreshes custom background path label.
    private func refreshBackgroundPathLabel() {
        if let path = AppSettings.shared.customBackgroundFilePath, !path.isEmpty {
            customBackgroundPathLabel.stringValue = path
        } else {
            customBackgroundPathLabel.stringValue = "No custom image selected"
        }
    }

    /// Enables/disables background-related controls based on selected mode.
    private func refreshBackgroundControlState() {
        let mode = AppSettings.shared.backgroundMode
        colorWell.isEnabled = (mode == .solid)
        bundledBackgroundPicker.isEnabled = (mode == .bundledImage)
        chooseBackgroundButton.isEnabled = true
        clearBackgroundButton.isEnabled = (AppSettings.shared.customBackgroundFilePath != nil)
    }
}
