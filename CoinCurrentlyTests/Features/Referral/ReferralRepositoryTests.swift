import CoreImage.CIFilterBuiltins
import Foundation
import Testing
import UIKit
@testable import CoinCurrently

@Suite("ReferralLinkParser Tests")
struct ReferralLinkParserTests {
    
    @Test("inviteCode extracts code from invite URL")
    func inviteCodeExtractsFromURL() {
        let code = ReferralLinkParser.inviteCode(
            from: "https://coincurrently.app/invite/xpuH84SVsh"
        )
        
        #expect(code == "xpuH84SVsh")
    }
    
    @Test("inviteCode rejects partial decode fragments")
    func inviteCodeRejectsPartialDecode() {
        let code = ReferralLinkParser.inviteCode(from: "Ho:")
        
        #expect(code == nil)
    }
    
    @Test("normalizedInviteLink rebuilds invite URL from payload")
    func normalizedInviteLinkRebuildsURL() {
        let link = ReferralLinkParser.normalizedInviteLink(
            from: "https://coincurrently.app/invite/xpuH84SVsh"
        )
        
        #expect(link == "https://coincurrently.app/invite/xpuH84SVsh")
    }
}

@Suite("ReferralCodeResult Tests")
struct ReferralCodeResultTests {
    
    @Test("decode reads referral code header")
    func decodeReadsHeaders() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
        let data = try #require(image.pngData())
        let url = try #require(URL(string: "https://api.coincurrently.app/referral-code"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "raw_code": "ABC1234567"
            ]
        ))
        
        let result = ReferralCodeResult.decode(data: data, response: response)
        
        #expect(result?.code == "ABC1234567")
        #expect(result?.inviteLink == "https://coincurrently.app/invite/ABC1234567")
        #expect(result?.qrImage != nil)
    }
    
    @Test("decode returns nil when code header is missing")
    func decodeReturnsNilWithoutCodeHeader() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
        let data = try #require(image.pngData())
        let url = try #require(URL(string: "https://api.coincurrently.app/referral-code"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [:]
        ))
        
        let result = ReferralCodeResult.decode(data: data, response: response)
        
        #expect(result == nil)
    }
}

@Suite("QRCodeDecoder Tests")
struct QRCodeDecoderTests {
    
    @Test("extracts invite link from generated qr code")
    func extractsInviteLinkFromGeneratedQRCode() {
        let link = "https://coincurrently.app/invite/ABC1234567"
        let image = generateTestQRCode(from: link)
        
        let result = QRCodeDecoder.string(from: image)
        
        #expect(result == link)
    }
    
    private func generateTestQRCode(from string: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"
        
        guard let outputImage = filter.outputImage else {
            return UIImage()
        }
        
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
}

@Suite("ReferralRepository Tests")
struct ReferralRepositoryTests {

    @Test("getReferralCode returns result from headers and png body")
    func getReferralCodeReturnsResult() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
        let data = try #require(image.pngData())
        let url = try #require(URL(string: "https://api.coincurrently.app/referral-code"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["raw_code": "ABC1234567"]
        ))
        let mock = MockRepoNetworkManager(getRawResult: (data, response))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.getReferralCode()

        let callCount = await mock.getRawCallCount
        #expect(callCount == 1)
        #expect(result?.code == "ABC1234567")
        #expect(result?.qrImage != nil)
    }

    @Test("getReferralCode returns nil when network fails")
    func getReferralCodeReturnsNil() async {
        let mock = MockRepoNetworkManager(getRawResult: nil)

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.getReferralCode()

        #expect(result == nil)
    }
    
    @Test("getReferralCode returns nil for unsupported response")
    func getReferralCodeReturnsNilForUnsupportedResponse() async throws {
        let data = Data([0x00, 0x01, 0x02, 0x03])
        let url = try #require(URL(string: "https://api.coincurrently.app/referral-code"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["raw_code": "ABC1234567"]
        ))
        let mock = MockRepoNetworkManager(getRawResult: (data, response))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.getReferralCode()

        #expect(result == nil)
    }

    @Test("redeemCode returns success on 200")
    func redeemCodeReturnsSuccess() async {
        let mock = MockRepoNetworkManager(postResult: (EmptyResponse(), 200))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.redeemCode(refCode: "ABC1234567")

        let callCount = await mock.postCallCount
        #expect(callCount == 1)
        #expect(result == .success)
    }

    @Test("redeemCode maps 404 to invalid code")
    func redeemCodeReturnsInvalidCode() async {
        let mock = MockRepoNetworkManager(postResult: (nil, 404))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.redeemCode(refCode: "ABC1234567")

        #expect(result == .invalidCode)
        #expect(result.errorMessage == "Invalid code")
    }

    @Test("redeemCode maps 400 to already referred")
    func redeemCodeReturnsAlreadyReferred() async {
        let mock = MockRepoNetworkManager(postResult: (nil, 400))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.redeemCode(refCode: "ABC1234567")

        #expect(result == .alreadyReferred)
        #expect(result.errorMessage == "You've already been referred by someone else.")
    }

    @Test("redeemCode maps 418 to self redeem")
    func redeemCodeReturnsSelfRedeem() async {
        let mock = MockRepoNetworkManager(postResult: (nil, 418))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.redeemCode(refCode: "ABC1234567")

        #expect(result == .selfRedeem)
        #expect(result.errorMessage == "You can't redeem yourself, silly.")
    }

    @Test("redeemCode maps unknown status to failure")
    func redeemCodeReturnsFailure() async {
        let mock = MockRepoNetworkManager(postResult: (nil, 500))

        let repo = ReferralRepositoryImp(networkManager: mock, storageManager: emptyStorageManager())
        let result = await repo.redeemCode(refCode: "ABC1234567")

        #expect(result == .failure)
    }
}
