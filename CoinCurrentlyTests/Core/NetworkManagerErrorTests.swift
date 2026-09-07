import Foundation
import Testing
@testable import CoinCurrently

@Suite("NetworkManagerError Tests")
struct NetworkManagerErrorTests {

    @Test("isUpstreamNotFound reads 404 from JSON detail")
    func isUpstreamNotFoundReadsDetail() {
        let data = Data(
            #"{"detail":"System.Net.Http.HttpRequestException: Response status code does not indicate success: 404 (Not Found)."}"#.utf8
        )

        #expect(NetworkManagerError.isUpstreamNotFound(in: data))
    }

    @Test("isUpstreamNotFound ignores unrelated 500 detail")
    func isUpstreamNotFoundIgnoresUnrelatedDetail() {
        let data = Data(#"{"detail":"An unexpected error occurred."}"#.utf8)

        #expect(NetworkManagerError.isUpstreamNotFound(in: data) == false)
    }

    @Test("resolved remaps a 500 with upstream 404 detail to notFound")
    func resolvedRemapsWrappedNotFound() {
        let data = Data(
            #"{"detail":"System.Net.Http.HttpRequestException: Response status code does not indicate success: 404 (Not Found)."}"#.utf8
        )

        #expect(NetworkManagerError.resolved(statusCode: 500, data: data) == .notFound)
        #expect(NetworkManagerError.resolved(statusCode: 500, data: Data(#"{"detail":"An unexpected error occurred."}"#.utf8)) == .serverError)
    }

    @Test("treatsNotFoundAsEmpty is only set for public treasury lists")
    func treatsNotFoundAsEmptyOnlyForPublicTreasury() {
        #expect(Endpoint.publicTreasury(entity: .companies, coinId: "dogecoin").treatsNotFoundAsEmpty)
        #expect(Endpoint.treasuryDetail(entityId: "strategy").treatsNotFoundAsEmpty == false)
        #expect(Endpoint.global.treatsNotFoundAsEmpty == false)
    }
}
