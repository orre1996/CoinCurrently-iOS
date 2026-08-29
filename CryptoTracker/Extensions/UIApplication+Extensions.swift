//
//  UIApplication+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-07.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var window: UIWindow? {
        guard let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let firstWindow = firstScene.windows.first else { return nil }

        return firstWindow
    }
}
