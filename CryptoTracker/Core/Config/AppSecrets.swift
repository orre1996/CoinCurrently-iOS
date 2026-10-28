//
//  AppSecrets.swift
//  CoinCurrently
//

import Foundation

enum AppSecrets {
    /// Keyless CoinGecko API. No `/crypto` prefix and no API key.
    /// https://docs.coingecko.com/docs/keyless-public-api
    static let publicCoinGeckoAPIRoot = "https://api.coingecko.com/api/v3"

    private static let placeholderAPIBaseURL = "https://api.example.com"
    private static let placeholderBackendAPIKey = "your-backend-api-key"
    private static let placeholderAptabaseAppKey = "A-XX-0000000000"

    nonisolated(unsafe) private static let values: [String: Any] = loadValues()

    /// Backend origin with no trailing slash. Nil when market routes should use the keyless CoinGecko API.
    static var configuredBackendBaseURL: String? {
        normalizedBackendBaseURL(optionalString(for: "API_BASE_URL"))
    }

    /// Backend origin. Placeholder when no real backend is configured, so first-party routes stay off CoinGecko.
    static var apiBaseURL: String {
        configuredBackendBaseURL ?? placeholderAPIBaseURL
    }

    /// Market routes call `https://api.coingecko.com/api/v3` when no backend URL is configured.
    /// Unit tests keep the backend path shape so path assertions stay stable.
    static var usesPublicCoinGecko: Bool {
        shouldUsePublicCoinGecko(
            isRunningUnitTests: isRunningUnitTests,
            configuredBackendBaseURL: configuredBackendBaseURL
        )
    }

    static var backendAPIKey: String? {
        guard let value = optionalString(for: "BACKEND_API_KEY"),
              value != placeholderBackendAPIKey else {
            return nil
        }
        return value
    }

    static var aptabaseAppKey: String? {
        guard let value = optionalString(for: "APTABASE_APP_KEY"),
              value != placeholderAptabaseAppKey else {
            return nil
        }
        return value
    }

    static func shouldUsePublicCoinGecko(
        isRunningUnitTests: Bool,
        configuredBackendBaseURL: String?
    ) -> Bool {
        !isRunningUnitTests && configuredBackendBaseURL == nil
    }

    static func normalizedBackendBaseURL(_ value: String?) -> String? {
        guard var trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        guard !trimmed.isEmpty, trimmed != placeholderAPIBaseURL else {
            return nil
        }
        return trimmed
    }

    private static func loadValues() -> [String: Any] {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return [:]
        }
        return plist
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    private static func optionalString(for key: String) -> String? {
        guard let value = values[key] as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
