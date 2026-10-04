import Foundation

/// Locates files shipped in the target's SwiftPM resource bundle.
///
/// `Package.swift` declares `.copy("Resources")`, which preserves the folder, so
/// every file lands under `<bundle>/Contents/Resources/Resources/`. Plain
/// `Bundle.module.url(forResource:withExtension:)` lookups therefore miss them.
/// This helper looks inside that folder first and then falls back to the bundle
/// root, so a flat layout keeps working too.
enum BundledResources {
    /// Folder that `.copy("Resources")` preserves inside the resource bundle.
    static let folderName = "Resources"

    /// Returns the URL of a bundled resource, or `nil` if it is not present.
    /// - Parameters:
    ///   - name: Resource name without extension (or a full file name when `ext` is `nil`).
    ///   - ext: File extension, or `nil` when `name` already includes it.
    ///   - subdirectory: Optional folder below `Resources/` (e.g. `images`).
    ///   - bundle: Bundle to search (defaults to `Bundle.module`).
    static func url(
        forResource name: String,
        withExtension ext: String?,
        subdirectory: String? = nil,
        in bundle: Bundle = .module
    ) -> URL? {
        let trimmedSubdirectory = subdirectory?.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let nested = [folderName, trimmedSubdirectory]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: nested) {
            return url
        }
        let flat = (trimmedSubdirectory?.isEmpty ?? true) ? nil : trimmedSubdirectory
        return bundle.url(forResource: name, withExtension: ext, subdirectory: flat)
    }
}
