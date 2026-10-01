//
//  Localization.swift
//  CoinCurrently
//

import Foundation
import SwiftUI

/// Looks up copy in `Localizable.xcstrings` using the in-app language.
enum Localization {
    static var locale: Locale { AppLanguagePreference.stored.resolve().locale }

    static func string(_ key: String, locale: Locale? = nil) -> String {
        let resource = LocalizedStringResource(
            String.LocalizationValue(key),
            locale: locale ?? self.locale
        )
        return String(localized: resource)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }
}

extension Text {
    /// Catalog lookup. Custom names that aren’t in the catalog show as typed.
    init(catalog key: String) {
        self.init(LocalizedStringKey(key))
    }
}
