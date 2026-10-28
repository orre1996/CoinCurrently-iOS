import Testing
@testable import CoinCurrently

@Suite("Public CoinGecko fallback")
struct PublicCoinGeckoFallbackTests {
    @Test("missing or placeholder backend URL uses the keyless API")
    func usesKeylessAPI() {
        #expect(AppSecrets.shouldUsePublicCoinGecko(isRunningUnitTests: false, configuredBackendBaseURL: nil))
        #expect(AppSecrets.normalizedBackendBaseURL(nil) == nil)
        #expect(AppSecrets.normalizedBackendBaseURL("") == nil)
        #expect(AppSecrets.normalizedBackendBaseURL("   ") == nil)
        #expect(AppSecrets.normalizedBackendBaseURL("https://api.example.com") == nil)
        #expect(AppSecrets.normalizedBackendBaseURL("https://api.example.com/") == nil)
    }

    @Test("a real backend URL stays on the proxy path")
    func keepsBackendProxy() {
        let backend = "https://backend.example"
        #expect(AppSecrets.normalizedBackendBaseURL("\(backend)/") == backend)
        #expect(!AppSecrets.shouldUsePublicCoinGecko(isRunningUnitTests: false, configuredBackendBaseURL: backend))
        #expect(!AppSecrets.shouldUsePublicCoinGecko(isRunningUnitTests: true, configuredBackendBaseURL: nil))
        #expect(
            Endpoint.marketAPIRoot(usesPublicCoinGecko: false, serverBaseURL: backend)
                == "\(backend)/crypto/api/v3"
        )
    }

    @Test("keyless market root drops the crypto prefix")
    func keylessMarketRoot() {
        #expect(
            Endpoint.marketAPIRoot(usesPublicCoinGecko: true, serverBaseURL: "https://api.example.com")
                == "https://api.coingecko.com/api/v3"
        )
    }

    @Test("first-party routes still need the backend")
    func backendRoutes() {
        #expect(Endpoint.gasFees(includeHistory: false).requiresBackend)
        #expect(Endpoint.user().requiresBackend)
        #expect(!Endpoint.toplist(itemsPerPage: 10, sortOption: .mktCapDesc, currency: CurrencyModel()).requiresBackend)
        #expect(!Endpoint.fearAndGreed.requiresBackend)
    }
}
