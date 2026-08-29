//
//  PremiumIcon.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/29/26.
//

import SwiftUI

enum PremiumSize: CGFloat {
    case small = 10
    case large = 8 // 16
}

struct PremiumIcon: View {
    var backgroundColor: Color = .primary20
    var size: PremiumSize = .large
    
    var body: some View {
        Image.premiumLogo
            .resizable()
            .frame(width: 52, height: 52)
            .padding(size.rawValue)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}
