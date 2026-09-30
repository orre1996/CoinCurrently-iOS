//
//  RectangularNewsWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-07.
//

import SwiftUI
import WidgetKit

struct RectangularNewsWidget: View {
    @Environment(\.colorScheme) var scheme

    var entry: NewsItem?
    
    var body: some View {
        if let url = URL(string: entry?.news_url ?? .appName) {
            ZStack {
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                VStack(spacing: 0) {
                    Text(entry?.title ?? "CoinCurrently")
                        .font(.satoshiBold(12))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    HStack(spacing: 4) {
                        Image("iconNoBackground")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundColor(Color.onSurfaceDimmer(for: scheme))
                        
                        Text(entry?.source_name ?? AppCopy.string("Crypto news"))
                            .font(.satoshiBold(10))
                            .minimumScaleFactor(0.8)
                            .foregroundColor(Color.onSurfaceDimmer(for: scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    }
                }
                .padding(4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetURL(url)
        }
    }
}

struct RectangularLockScreenNewsWidget_Previews: PreviewProvider {
    static var previews: some View {
        RectangularNewsWidget()
    }
}
