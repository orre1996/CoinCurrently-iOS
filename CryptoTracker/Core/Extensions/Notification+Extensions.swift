//
//  Notification+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-07.
//

import Foundation

extension Notification.Name {
    static let Snackbar = Notification.Name("Snackbar")
    static let canScroll = Notification.Name("canScroll")
    static let checkForBannedUser = Notification.Name("checkForBannedUser")
    static let downloadNewToplist = Notification.Name("downloadNewToplist")
    static let showRatingView = Notification.Name("showRatingView")
    static let currencySent = Notification.Name("currencySent")
    static let closeAllOverlays = Notification.Name("CloseAllOverlays")
    static let reloadViews = Notification.Name("ReloadViews")
    static let tabDoubleTapped = Notification.Name("TabDoubleTapped")
    static let fromPush = Notification.Name("Push")
    static let backFromBackground = Notification.Name("BackFromBackground")
    static let changeMarketPage = Notification.Name("changeMarketPage")
    static let sync = Notification.Name("Sync")
    static let sortCategoriesToplist = Notification.Name("sortCategoriesToplist")
    static let newTransaction = Notification.Name("newTransaction")
    static let colorBlindnessFilterChanged = Notification.Name("colorBlindnessFilterChanged")
}
