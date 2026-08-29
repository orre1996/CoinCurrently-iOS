//
//  UIWindow+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-12-13.
//

import UIKit

extension UIWindow {
    static var key: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    static var isLandscape: Bool {
        return UIApplication.shared.window?.windowScene?.interfaceOrientation.isLandscape ?? false
    }
}
