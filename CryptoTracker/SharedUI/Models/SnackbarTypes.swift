//
//  SnackbarTypes.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-07.
//

import Foundation

enum SnackbarTypes {
    case success, failure, information
}

enum SnackbarConstants {
    static let displayDuration: TimeInterval = 7.5
    static let animationDuration: TimeInterval = 0.75
}

func showSnackBar(message: String, type: SnackbarTypes) {
    asyncMain {
        NotificationCenter.default.post(Notification(name: .Snackbar, object: nil, userInfo: [
            "message" : message,
            "type" : type
        ]))
    }
}

func showBuyPro() {
    asyncMain {
        NotificationCenter.default.post(Notification(name: .buyPro, object: nil, userInfo: [:]))
    }
}
