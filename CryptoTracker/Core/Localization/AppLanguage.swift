//
//  AppLanguage.swift
//  CoinCurrently
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    case english = "en"
    case russian = "ru"
    case german = "de"
    case polish = "pl"
    case spanish = "es"
    case vietnamese = "vi"
    case french = "fr"
    case portuguese = "pt"
    case arabic = "ar"
    case bulgarian = "bg"
    case czech = "cs"
    case danish = "da"
    case greek = "el"
    case finnish = "fi"
    case hebrew = "he"
    case hindi = "hi"
    case croatian = "hr"
    case hungarian = "hu"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case lithuanian = "lt"
    case dutch = "nl"
    case norwegian = "no"
    case romanian = "ro"
    case slovak = "sk"
    case slovenian = "sl"
    case swedish = "sv"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case chineseSimplified = "zh"
    case chineseTraditional = "zh-tw"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .chineseSimplified:
            return Locale(identifier: "zh-Hans")
        case .chineseTraditional:
            return Locale(identifier: "zh-Hant")
        default:
            return Locale(identifier: rawValue)
        }
    }

    /// Name shown in that language.
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .german: return "Deutsch"
        case .polish: return "Polski"
        case .spanish: return "Español"
        case .vietnamese: return "Tiếng Việt"
        case .french: return "Français"
        case .portuguese: return "Português"
        case .arabic: return "العربية"
        case .bulgarian: return "Български"
        case .czech: return "Čeština"
        case .danish: return "Dansk"
        case .greek: return "Ελληνικά"
        case .finnish: return "Suomi"
        case .hebrew: return "עברית"
        case .hindi: return "हिन्दी"
        case .croatian: return "Hrvatski"
        case .hungarian: return "Magyar"
        case .indonesian: return "Bahasa Indonesia"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .lithuanian: return "Lietuvių"
        case .dutch: return "Nederlands"
        case .norwegian: return "Norsk"
        case .romanian: return "Română"
        case .slovak: return "Slovenčina"
        case .slovenian: return "Slovenščina"
        case .swedish: return "Svenska"
        case .thai: return "ไทย"
        case .turkish: return "Türkçe"
        case .ukrainian: return "Українська"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        }
    }

    var englishName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Russian"
        case .german: return "German"
        case .polish: return "Polish"
        case .spanish: return "Spanish"
        case .vietnamese: return "Vietnamese"
        case .french: return "French"
        case .portuguese: return "Portuguese"
        case .arabic: return "Arabic"
        case .bulgarian: return "Bulgarian"
        case .czech: return "Czech"
        case .danish: return "Danish"
        case .greek: return "Greek"
        case .finnish: return "Finnish"
        case .hebrew: return "Hebrew"
        case .hindi: return "Hindi"
        case .croatian: return "Croatian"
        case .hungarian: return "Hungarian"
        case .indonesian: return "Indonesian"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .lithuanian: return "Lithuanian"
        case .dutch: return "Dutch"
        case .norwegian: return "Norwegian"
        case .romanian: return "Romanian"
        case .slovak: return "Slovak"
        case .slovenian: return "Slovenian"
        case .swedish: return "Swedish"
        case .thai: return "Thai"
        case .turkish: return "Turkish"
        case .ukrainian: return "Ukrainian"
        case .chineseSimplified: return "Chinese (Simplified)"
        case .chineseTraditional: return "Chinese (Traditional)"
        }
    }

    var subtitle: String? {
        nativeName == englishName ? nil : englishName
    }

    /// Picks the closest supported language from the device’s preferred list.
    static func matching(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        for identifier in preferredLanguages {
            if let match = match(identifier: identifier) {
                return match
            }
        }
        return .english
    }

    static func match(identifier: String) -> AppLanguage? {
        let normalized = identifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        if let exact = AppLanguage(rawValue: normalized) {
            return exact
        }

        let locale = Locale(identifier: identifier)
        let code = locale.language.languageCode?.identifier
            ?? normalized.split(separator: "-").first.map(String.init)
            ?? normalized
        let script = locale.language.script?.identifier
        let region = locale.region?.identifier

        if code == "zh" || normalized.hasPrefix("zh") {
            if script == "Hant"
                || region == "TW"
                || region == "HK"
                || region == "MO"
                || normalized.contains("hant")
                || normalized.contains("-tw")
                || normalized.contains("-hk")
                || normalized.contains("-mo")
            {
                return .chineseTraditional
            }
            return .chineseSimplified
        }

        if code == "pt" || normalized.hasPrefix("pt") {
            return .portuguese
        }

        if code == "nb" || code == "no" || code == "nn"
            || normalized.hasPrefix("nb")
            || normalized.hasPrefix("nn")
            || normalized.hasPrefix("no")
        {
            return .norwegian
        }

        return AppLanguage(rawValue: code)
    }
}

/// `system` follows the device language when the app supports it.
enum AppLanguagePreference: Equatable {
    case system
    case fixed(AppLanguage)

    var storageValue: String {
        switch self {
        case .system:
            return "system"
        case .fixed(let language):
            return language.rawValue
        }
    }

    var settingsSubtitle: String {
        switch self {
        case .system:
            return "System"
        case .fixed(let language):
            return language.nativeName
        }
    }

    static func from(storage: String?) -> AppLanguagePreference {
        guard let storage, storage != "system", !storage.isEmpty else {
            return .system
        }
        if let language = AppLanguage(rawValue: storage) {
            return .fixed(language)
        }
        return .system
    }

    func resolve() -> AppLanguage {
        switch self {
        case .system:
            return .matching()
        case .fixed(let language):
            return language
        }
    }

    static var stored: AppLanguagePreference {
        let stored: String? = SettingsManager.shared.get(key: AppSettingKey.selectedLanguage)
        return from(storage: stored)
    }
}
