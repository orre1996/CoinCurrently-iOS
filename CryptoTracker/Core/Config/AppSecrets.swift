//
//  AppSecrets.swift
//  CoinCurrently
//

import Foundation

enum AppSecrets {
    nonisolated(unsafe) private static let values: [String: Any] = loadValues()

    static var apiBaseURL: String { requiredString(for: "API_BASE_URL") }
    static var backendAPIKey: String { requiredString(for: "BACKEND_API_KEY") }
    static var aptabaseAppKey: String { requiredString(for: "APTABASE_APP_KEY") }

    private static func loadValues() -> [String: Any] {
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            return plist
        }

        if isRunningUnitTests {
            return testFallbackValues
        }

        fatalError(
            """
            Missing Secrets.plist in the app bundle.
            Copy Config/Secrets.example.plist to Config/Secrets.plist, fill in your values, \
            and ensure Secrets.plist is included in the target's Copy Bundle Resources build phase.
            """
        )
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    private static var testFallbackValues: [String: Any] {
        [
            "API_BASE_URL": "https://api.example.com",
            "BACKEND_API_KEY": "test-backend-api-key",
            "APTABASE_APP_KEY": "A-US-0000000000"
        ]
    }

    private static func requiredString(for key: String) -> String {
        guard let value = values[key] as? String, !value.isEmpty else {
            fatalError("Missing or empty value for \(key) in Secrets.plist")
        }
        return value
    }
}
