//
//  Image+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-17.
//

import SwiftUI
import WidgetKit

extension Image {
    // MARK: - Social media
    static let x = Image("x")
    static let meta = Image("meta")
    static let reddit = Image("reddit")
    static let referral = Image(systemName: "person.2")
    
    // MARK: - Price change
    static let trendUp = Image("trendUp")
    static let trendDown = Image("trendDown")
    static let trendStill = Image("trendStill")
    
    static let cross = Image("cross")
    static let minus = Image("minus")
    static let plus = Image("plus")
    static let check = Image("check")
    static let infinity = Image("infinity")
    static let delete = Image("delete")
    static let remove = Image("remove")
    static let list = Image("list")
    
    static let premiumLogo = Image("premiumLogo")
    
    static let feedback = Image("feedback")
    static let more = Image("more")
    static let edit = Image("edit")
    static let candlestick = Image("candlestick")
    static let lineChart = Image("lineChart")
    
    static let walletImport = Image("walletImport")
    static let add = Image("add")
    static let converter = Image("converter")
    
    static let favoriteOutline = Image("favoriteOutline")
    static let favoriteFilled = Image("favoriteFilled")
    
    static let compare = Image("compare")
    static let changeCoin = Image("changeCoin")
    static let external = Image("external")
    
    static let hide = Image("hide")
    static let unhide = Image("unhide")
    static let percent = Image("percent")
    
    static let deposit = Image("deposit")
    static let withdraw = Image("withdraw")
    static let trade = Image("trade")
    static let date = Image("date")
    static let time = Image("time")
    
    static let chevronRight = Image("chevronRight")
    static let chevronUp = Image("chevronUp")
    static let chevronLeft = Image("chevronLeft")
    static let chevronDown = Image("chevronDown")
    
    static let alert = Image("alert")
    static let star = Image(systemName: "star")
    static let starFill = Image(systemName: "star.fill")
    static let bannerTransparent = Image("bannerTransparent")
    static let trashFill = Image(systemName: "trash.fill")
    static let refresh = Image(systemName: "arrow.triangle.2.circlepath")
    static let pencil = Image(systemName: "pencil")
    
    static let checkCircle = Image("checkCircle")
    static let xCircle = Image("xCircle")
    static let copy = Image("copy")
    static let share = Image("share")
    
    static let website = Image("website")
    static let whitepaper = Image("whitepaper")
    static let repository = Image("repository")
    
    static let medium = Image("medium")
    static let steemit = Image("steemit")
    static let telegram = Image("telegram")
    static let appStore = Image("appStore")

    /// Returns the appropriate icon for a given URL string (e.g. steemit, medium, telegram, or website)
    static func icon(for url: String) -> Image {
        let lowercased = url.lowercased()
        if lowercased.contains("steemit") { return .steemit }
        if lowercased.contains("medium.com") { return .medium }
        if lowercased.contains("t.me") || lowercased.contains("telegram") { return .telegram }
        return .website
    }
    
    // MARK: - NavigationBar
    static let info = Image("info")
    
    // MARK: - TabbarItems
    static let sort = Image("sort")
    static let search = Image("search")
    static let heatmap = Image(systemName: "square.grid.2x2")
    static let widget = Image(systemName: "widget.small")
    
    static let arrowUp = Image("arrowUp")
    static let arrowLeft = Image(systemName: "arrow.left")
    static let arrowRight = Image(systemName: "arrow.right")
    static let sync = Image(systemName: "arrow.triangle.2.circlepath")
    static let save = Image(systemName: "star")
    
    // MARK: - Enjoy the app
    static let discordLogo = Image("discord")
    static let explorerLogo = Image("explorer")
    
    static let sector = Image("sector")
    
    static let checkmark = Image(systemName: "checkmark")
    static let lock = Image(systemName: "lock")
    static let clearButton = Image(systemName: "multiply.circle.fill")
    
    static let lightning = Image("lightning")
    static let home = Image("home")
    static let portfolio = Image("portfolio")
    static let market = Image("market")
    static let news = Image("news")
    static let settings = Image("settings")
}

#if IS_WIDGET
extension Image {
    static func getAppIcon(for scheme: ColorScheme) -> Image {
        switch scheme {
        case .light:
            return Image("AppIconLight")
        case .dark:
            return Image("AppIconDark")
        @unknown default:
            return Image("AppIconDark")
        }
    }
}
#endif
