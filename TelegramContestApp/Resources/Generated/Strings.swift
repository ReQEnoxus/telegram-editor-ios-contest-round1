// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum Screens {
    internal enum Editor {
      internal enum Alert {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Screens.Editor.Alert.cancel")
        /// Clear Painting
        internal static let clearAll = L10n.tr("Localizable", "Screens.Editor.Alert.clearAll")
        /// Delete unsaved changes
        internal static let scrapAll = L10n.tr("Localizable", "Screens.Editor.Alert.scrapAll")
      }
      internal enum Modes {
        /// Draw
        internal static let draw = L10n.tr("Localizable", "Screens.Editor.Modes.draw")
        /// Text
        internal static let text = L10n.tr("Localizable", "Screens.Editor.Modes.text")
      }
      internal enum Navbar {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Screens.Editor.Navbar.cancel")
        /// Clear All
        internal static let clearAll = L10n.tr("Localizable", "Screens.Editor.Navbar.clearAll")
        /// Done
        internal static let done = L10n.tr("Localizable", "Screens.Editor.Navbar.done")
        /// Zoom Out
        internal static let zoomOut = L10n.tr("Localizable", "Screens.Editor.Navbar.zoomOut")
      }
    }
    internal enum Permissions {
      /// Allow Access
      internal static let accessButtonTitle = L10n.tr("Localizable", "Screens.Permissions.accessButtonTitle")
      /// Access Your Photos and Videos
      internal static let accessPhotosAndVideos = L10n.tr("Localizable", "Screens.Permissions.accessPhotosAndVideos")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
