//
//  ReferralCodeResponse.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/30/26.
//

#if IS_APP
import CoreImage
import Vision
#endif
import Foundation
import UIKit

struct ReferralCodeResult {
    let qrImage: UIImage
    let code: String
    
    var inviteLink: String {
        "https://coincurrently.app/invite/\(code)"
    }
    
    static func decode(data: Data, response: HTTPURLResponse) -> ReferralCodeResult? {
        guard let image = UIImage(data: data) else { return nil }
        
        let code = response.headerValue(for: "raw_code")
        
        guard let code, !code.isEmpty else { return nil }
        
        return ReferralCodeResult(
            qrImage: image,
            code: code
        )
    }
}

struct CachedReferralCodeData: Codable {
    let code: String
    let qrImageData: Data
    
    init(result: ReferralCodeResult, imageData: Data) {
        self.code = result.code
        self.qrImageData = imageData
    }
    
    var asResult: ReferralCodeResult? {
        guard let image = UIImage(data: qrImageData) else { return nil }
        return ReferralCodeResult(qrImage: image, code: code)
    }
}

struct RedeemCodeRequest: Codable {
    let refCode: String
}

enum RedeemCodeResult: Equatable {
    case success
    case invalidCode
    case alreadyReferred
    case selfRedeem
    case failure

    init(statusCode: Int) {
        switch statusCode {
        case 200:
            self = .success
        case 404:
            self = .invalidCode
        case 400:
            self = .alreadyReferred
        case 418:
            self = .selfRedeem
        default:
            self = .failure
        }
    }

    var errorMessage: String? {
        switch self {
        case .success:
            nil
        case .invalidCode:
            Localization.string("Invalid code")
        case .alreadyReferred:
            Localization.string("You've already been referred by someone else.")
        case .selfRedeem:
            Localization.string("You can't redeem yourself, silly.")
        case .failure:
            Localization.string("Something went wrong. Please try again.")
        }
    }
}

private extension HTTPURLResponse {
    func headerValue(for name: String) -> String? {
        let match = allHeaderFields.first { key, _ in
            (key as? String)?.caseInsensitiveCompare(name) == .orderedSame
        }
        
        guard let value = match?.value as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum ReferralLinkParser {
    private static let inviteCodePattern = #"/invite/([^/?#\s]+)"#
    
    static func inviteCode(from link: String) -> String? {
        if let code = DeeplinkHandler.referralCode(from: link) {
            return code
        }
        
        if let regex = try? NSRegularExpression(pattern: inviteCodePattern),
           let match = regex.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)),
           let range = Range(match.range(at: 1), in: link) {
            let code = String(link[range])
            return code.isEmpty ? nil : code
        }
        
        guard let last = link.split(separator: "/").last.map(String.init),
              !last.contains(":"),
              last.count >= 6 else {
            return nil
        }
        
        return last
    }
    
    static func normalizedInviteLink(from payload: String) -> String? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if DeeplinkHandler.referralCode(from: trimmed) != nil {
            return trimmed
        }
        
        if let code = inviteCode(from: trimmed) {
            return "https://coincurrently.app/invite/\(code)"
        }
        
        return nil
    }
}

#if IS_APP
enum QRCodeDecoder {
    static func string(from image: UIImage) -> String? {
        let images = [normalized(image)] + [2, 3].compactMap { scaled(image, factor: CGFloat($0)) }
        
        var payloads: [String] = []
        
        for candidate in images {
            guard let cgImage = cgImage(from: candidate) else { continue }
            
            payloads.append(contentsOf: detectAllWithVision(cgImage: cgImage))
            if let payload = detectWithCIDetector(cgImage: cgImage) {
                payloads.append(payload)
            }
        }
        
        return bestInvitePayload(from: payloads)
    }
    
    private static func bestInvitePayload(from payloads: [String]) -> String? {
        let normalizedLinks = payloads.compactMap { ReferralLinkParser.normalizedInviteLink(from: $0) }
        if let bestLink = normalizedLinks.max(by: { $0.count < $1.count }) {
            return bestLink
        }
        
        return payloads.max(by: { $0.count < $1.count })
    }
    
    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
    
    private static func scaled(_ image: UIImage, factor: CGFloat) -> UIImage? {
        guard factor > 0 else { return nil }
        
        let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        guard size.width > 0, size.height > 0 else { return nil }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private static func cgImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage {
            return cgImage
        }
        
        guard let ciImage = image.ciImage else { return nil }
        
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    private static func detectAllWithVision(cgImage: CGImage) -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil else { return [] }
        
        return request.results?.compactMap(\.payloadStringValue) ?? []
    }
    
    private static func detectWithCIDetector(cgImage: CGImage) -> String? {
        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
        return features?.compactMap(\.messageString).max(by: { $0.count < $1.count })
    }
}
#endif
