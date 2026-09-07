//
//  NetworkManagerError.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-09.
//

import Foundation

enum NetworkManagerError: Int, Error, Equatable {
    case invalidUrl
    case invalidData
    case invalidRequest = 400
    case unauthorizedRequest = 401
    case forbiddenRequest = 403
    case notFound = 404
    case tooManyRequests = 429
    case serverError = 500
    case apiUnavailable = 503
    case noInternetConnection = 997
    case couldntGenerateIdToken = 998
    case unknownError = 999
    
    func errorMessage(date: Date?) -> String {
        let cacheDateSuffix: String = {
            guard let date else { return "" }
            let timeSuffix = Date.uses24HourClock ? "HH:mm" : "hh:mm a"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd 'at' \(timeSuffix)"
            return " Showing data from \(dateFormatter.string(from: date))"
        }()
        switch self {
        case .invalidUrl:
            return "Invalid URL. Please contact support.\(cacheDateSuffix)"
        case .invalidData:
            return "Failed to parse response data.\(cacheDateSuffix)"
        case .noInternetConnection:
            return "No internet connection.\(cacheDateSuffix)"
        case .invalidRequest:
            return "Bad request. Please try again.\(cacheDateSuffix)"
        case .unauthorizedRequest:
            return "Authentication required. Try restarting the app.\(cacheDateSuffix)"
        case .forbiddenRequest:
            return "Access denied. You don't have permission.\(cacheDateSuffix)"
        case .notFound:
            return "Resource not found.\(cacheDateSuffix)"
        case .tooManyRequests:
            return "Too many requests. Please wait a moment.\(cacheDateSuffix)"
        case .serverError:
            return "Server error. Please try again later.\(cacheDateSuffix)"
        case .apiUnavailable:
            return "Service temporarily unavailable.\(cacheDateSuffix)"
        case .couldntGenerateIdToken:
            return "Failed to authenticate. Try restarting the app.\(cacheDateSuffix)"
        case .unknownError:
            return "Something went wrong. Check your connection.\(cacheDateSuffix)"
        }
    }
}

extension NetworkManagerError {
    /// Backend error bodies use `{ "detail": "..." }`. Upstream 404s are often
    /// forwarded as 500s with a `HttpRequestException` in `detail`.
    static func resolved(statusCode: Int, data: Data) -> NetworkManagerError? {
        if isUpstreamNotFound(in: data) {
            return .notFound
        }
        return NetworkManagerError(rawValue: statusCode)
    }

    static func isUpstreamNotFound(in data: Data) -> Bool {
        guard let detail = (try? JSONDecoder().decode(APIErrorDetail.self, from: data))?.detail
                ?? String(data: data, encoding: .utf8),
              !detail.isEmpty else {
            return false
        }

        return detail.contains("404") && detail.range(of: "Not Found", options: .caseInsensitive) != nil
    }

    static func from(caughtError error: Error) -> NetworkManagerError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                return .noInternetConnection
            default:
                break
            }
        }
        if error is DecodingError {
            return .invalidData
        }
        return .unknownError
    }
}

private struct APIErrorDetail: Decodable {
    let detail: String?
}
