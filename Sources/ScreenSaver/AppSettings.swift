import AppKit
import Foundation

/// Notification names used for propagating settings changes through the app.
extension Notification.Name {
    /// Posted when visual style settings change (font, colors, animation, etc.).
    static let styleSettingsDidChange = Notification.Name("styleSettingsDidChange")
    /// Posted when quote-source settings change (theme/custom XML selection).
    static let quoteSourceDidChange = Notification.Name("quoteSourceDidChange")
}

/// Persisted user settings for the standalone app runtime.
///
/// This singleton wraps `UserDefaults` keys and emits notifications so live views
/// can immediately apply updated settings.
@MainActor
final class AppSettings {
    /// Global shared settings instance.
    static let shared = AppSettings()

    private enum Keys {
        static let fontName = "style.fontName"
        static let backgroundColorData = "style.backgroundColorData"
        static let backgroundMode = "style.backgroundMode"
        static let bundledBackgroundFileName = "style.bundledBackgroundFileName"
        static let customBackgroundFilePath = "style.customBackgroundFilePath"
        static let foregroundColorData = "style.foregroundColorData"
        static let fontSize = "style.fontSize"
        static let useProposedFont = "style.useProposedFont"
        static let baseQuoteSeconds = "style.baseQuoteSeconds"
        static let animationStyle = "style.animationStyle"
        static let showsAttribution = "style.showsAttribution"
        static let customQuoteFilePath = "content.customQuoteFilePath"
        static let bundledQuoteFileName = "content.bundledQuoteFileName"
    }

    /// Bundled theme descriptor.
    struct BundledTheme: Equatable {
        let title: String
        let fileName: String
    }

    static let bundledThemes: [BundledTheme] = [
        BundledTheme(title: "Mixed (Default)", fileName: "quotes.xml"),
        BundledTheme(title: "Generic", fileName: "generic-quotes.xml"),
        BundledTheme(title: "Leadership", fileName: "leadership-quotes.xml"),
        BundledTheme(title: "Kevin Samuels", fileName: "kevin-samuels-quotes.xml"),
        BundledTheme(title: "Stoicism", fileName: "stoicism-quotes.xml"),
        BundledTheme(title: "Comedic", fileName: "comedic-quotes.xml"),
        BundledTheme(title: "Greek Philosophers", fileName: "greek-philosophers-quotes.xml"),
        BundledTheme(title: "French Revolutionaries", fileName: "french-revolutionaries-quotes.xml")
    ]

    /// Background rendering mode.
    enum BackgroundMode: String {
        case solid
        case bundledImage
        case customImage
    }

    /// Supported quote entrance animation styles.
    enum AnimationStyle: String, CaseIterable {
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

    /// Bundled background descriptor.
    struct BundledBackground: Equatable {
        let title: String
        let fileName: String
    }

    static let bundledBackgrounds: [BundledBackground] = [
        BundledBackground(title: "Antique Parchment", fileName: "images/antique-parchment.png"),
        BundledBackground(title: "Gray Linen", fileName: "images/gray-linen.png"),
        BundledBackground(title: "Offwhite Fabric", fileName: "images/offwhite-fabric-texture.png"),
        BundledBackground(title: "Old Papyrus", fileName: "images/old-papyrus.png"),
        BundledBackground(title: "Old Parchment", fileName: "images/old-parchment.png"),
        BundledBackground(title: "White Paper", fileName: "images/white-paper.png")
    ]

    private let defaults = UserDefaults.standard

    private(set) var fontName: String
    private(set) var backgroundColor: NSColor
    private(set) var backgroundMode: BackgroundMode
    private(set) var bundledBackgroundFileName: String
    private(set) var customBackgroundFilePath: String?
    private(set) var foregroundColor: NSColor
    private(set) var fontSize: CGFloat
    private(set) var useProposedFont: Bool
    private(set) var baseQuoteSeconds: TimeInterval
    private(set) var animationStyle: AnimationStyle
    private(set) var showsAttribution: Bool
    private(set) var customQuoteFilePath: String?
    private(set) var bundledQuoteFileName: String

    /// Creates the settings store and hydrates values from `UserDefaults`.
    private init() {
        fontName = defaults.string(forKey: Keys.fontName) ?? "Papyrus"
        if
            let data = defaults.data(forKey: Keys.backgroundColorData),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        {
            backgroundColor = color
        } else {
            backgroundColor = .black
        }
        let storedMode = defaults.string(forKey: Keys.backgroundMode) ?? BackgroundMode.solid.rawValue
        backgroundMode = BackgroundMode(rawValue: storedMode) ?? .solid
        let storedBundledBackground = defaults.string(forKey: Keys.bundledBackgroundFileName) ?? "images/old-parchment.png"
        if AppSettings.bundledBackgrounds.contains(where: { $0.fileName == storedBundledBackground }) {
            bundledBackgroundFileName = storedBundledBackground
        } else {
            bundledBackgroundFileName = "images/old-parchment.png"
        }
        customBackgroundFilePath = defaults.string(forKey: Keys.customBackgroundFilePath)

        if
            let data = defaults.data(forKey: Keys.foregroundColorData),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        {
            foregroundColor = color
        } else {
            foregroundColor = .white
        }

        let storedSize = defaults.double(forKey: Keys.fontSize)
        fontSize = storedSize > 0 ? CGFloat(storedSize) : 48
        useProposedFont = defaults.object(forKey: Keys.useProposedFont) as? Bool ?? true
        let storedBaseSeconds = defaults.double(forKey: Keys.baseQuoteSeconds)
        baseQuoteSeconds = storedBaseSeconds > 0 ? storedBaseSeconds : 5.0
        let storedAnimation = defaults.string(forKey: Keys.animationStyle) ?? AnimationStyle.fade.rawValue
        animationStyle = AnimationStyle(rawValue: storedAnimation) ?? .fade
        showsAttribution = defaults.object(forKey: Keys.showsAttribution) as? Bool ?? false
        customQuoteFilePath = defaults.string(forKey: Keys.customQuoteFilePath)
        let storedBundled = defaults.string(forKey: Keys.bundledQuoteFileName) ?? "quotes.xml"
        if AppSettings.bundledThemes.contains(where: { $0.fileName == storedBundled }) {
            bundledQuoteFileName = storedBundled
        } else {
            bundledQuoteFileName = "quotes.xml"
        }
    }

    /// Updates preferred font family.
    /// - Parameter name: Installed font family name.
    func updateFontName(_ name: String) {
        guard name != fontName else { return }
        fontName = name
        defaults.set(name, forKey: Keys.fontName)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates solid background color.
    /// - Parameter color: Selected color value.
    func updateBackgroundColor(_ color: NSColor) {
        backgroundColor = color
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true) {
            defaults.set(data, forKey: Keys.backgroundColorData)
        }
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates background mode.
    /// - Parameter mode: Desired background rendering mode.
    func updateBackgroundMode(_ mode: BackgroundMode) {
        guard mode != backgroundMode else { return }
        backgroundMode = mode
        defaults.set(mode.rawValue, forKey: Keys.backgroundMode)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates bundled background file selection.
    /// - Parameter fileName: Relative bundled file path (e.g. `images/old-parchment.png`).
    func updateBundledBackgroundFileName(_ fileName: String) {
        guard AppSettings.bundledBackgrounds.contains(where: { $0.fileName == fileName }) else { return }
        guard fileName != bundledBackgroundFileName else { return }
        bundledBackgroundFileName = fileName
        defaults.set(fileName, forKey: Keys.bundledBackgroundFileName)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates custom background image path.
    /// - Parameter path: Absolute file path or `nil` to clear custom background.
    func updateCustomBackgroundFilePath(_ path: String?) {
        let normalized = path?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = (normalized?.isEmpty == true) ? nil : normalized
        guard value != customBackgroundFilePath else { return }
        customBackgroundFilePath = value
        if let value {
            defaults.set(value, forKey: Keys.customBackgroundFilePath)
        } else {
            defaults.removeObject(forKey: Keys.customBackgroundFilePath)
        }
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates foreground text color.
    /// - Parameter color: Selected text color.
    func updateForegroundColor(_ color: NSColor) {
        foregroundColor = color
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true) {
            defaults.set(data, forKey: Keys.foregroundColorData)
        }
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates quote font size.
    /// - Parameter size: Requested point size; clamped to supported range.
    func updateFontSize(_ size: CGFloat) {
        let clamped = min(max(size, 18), 140)
        guard clamped != fontSize else { return }
        fontSize = clamped
        defaults.set(Double(clamped), forKey: Keys.fontSize)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates whether quote XML font suggestions override the selected font.
    /// - Parameter enabled: `true` to prefer XML `<font>` values when present.
    func updateUseProposedFont(_ enabled: Bool) {
        guard enabled != useProposedFont else { return }
        useProposedFont = enabled
        defaults.set(enabled, forKey: Keys.useProposedFont)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates base quote display duration.
    /// - Parameter seconds: Base seconds value; clamped to supported range.
    func updateBaseQuoteSeconds(_ seconds: TimeInterval) {
        let clamped = min(max(seconds, 3.0), 20.0)
        guard clamped != baseQuoteSeconds else { return }
        baseQuoteSeconds = clamped
        defaults.set(clamped, forKey: Keys.baseQuoteSeconds)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates animation style.
    /// - Parameter style: Animation style to apply for new quote transitions.
    func updateAnimationStyle(_ style: AnimationStyle) {
        guard style != animationStyle else { return }
        animationStyle = style
        defaults.set(style.rawValue, forKey: Keys.animationStyle)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates attribution visibility.
    /// - Parameter shows: `true` to show attribution footer.
    func updateShowsAttribution(_ shows: Bool) {
        guard shows != showsAttribution else { return }
        showsAttribution = shows
        defaults.set(shows, forKey: Keys.showsAttribution)
        NotificationCenter.default.post(name: .styleSettingsDidChange, object: nil)
    }

    /// Updates custom quote XML path.
    /// - Parameter path: Absolute file path or `nil` to use bundled source.
    func updateCustomQuoteFilePath(_ path: String?) {
        let normalized = path?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = (normalized?.isEmpty == true) ? nil : normalized
        guard value != customQuoteFilePath else { return }
        customQuoteFilePath = value
        if let value {
            defaults.set(value, forKey: Keys.customQuoteFilePath)
        } else {
            defaults.removeObject(forKey: Keys.customQuoteFilePath)
        }
        NotificationCenter.default.post(name: .quoteSourceDidChange, object: nil)
    }

    /// Updates bundled quote XML file selection.
    /// - Parameter fileName: Bundled XML file name.
    func updateBundledQuoteFileName(_ fileName: String) {
        guard AppSettings.bundledThemes.contains(where: { $0.fileName == fileName }) else { return }
        guard fileName != bundledQuoteFileName else { return }
        bundledQuoteFileName = fileName
        defaults.set(fileName, forKey: Keys.bundledQuoteFileName)
        NotificationCenter.default.post(name: .quoteSourceDidChange, object: nil)
    }
}
