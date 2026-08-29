//
//  AppIconShortcutsManager.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-05.
//

import Foundation
import UIKit

enum ShortCut: String {
  case feedback
}

class AppIconShortcutsManager {
    private var items: [UIApplicationShortcutItem] = []
    
    @MainActor
    func configure() {
        items = []
        
        addItem(.feedback, "Uninstalling the app?", subtitle: "Share your feedback", UIApplicationShortcutIcon(systemImageName: "envelope"))

        UIApplication.shared.shortcutItems = items
    }
    
    @MainActor
    func performActionFor(_ shortcutItem: UIApplicationShortcutItem, completionHandler: ((Bool) -> Void)?) {
        if let url = URL(string: "https://www.google.se") {
            UIApplication.shared.open(url)
        }

        completionHandler?(true)
    }
    
    private func addItem(_ shortcut: ShortCut, _ title: String, subtitle: String, _ icon: UIApplicationShortcutIcon, userInfo: [String: NSSecureCoding] = [:]) {
        items.append(UIApplicationShortcutItem(
            type: shortcut.rawValue,
            localizedTitle: title,
            localizedSubtitle: subtitle,
            icon: icon,
            userInfo: userInfo
        ))
    }
}
