//
//  RectangularLockScreenNewsWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-07.
//

import SwiftUI
import WidgetKit

struct RectangularLockScreenNewsWidget: View {
    @Environment(\.colorScheme) var scheme

    var entry: NewsItem?
    
    var body: some View {
        if let url = URL(string: entry?.news_url ?? .appName) {
            ZStack {
                
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                
                VStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Image("iconNoBackground")
                            .resizable()
                            .frame(width: 14, height: 14)
                        
                        Rectangle()
                            .frame(width: 1, height: 10)
                            .foregroundColor(.onSurfaceDim(for: scheme))
                            .padding(.horizontal, 3)

                        Text(entry?.source_name ?? "Crypto news")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.onSurfaceDim(for: scheme))
                            .lineLimit(1)
                        
                        Spacer(minLength: 0)
                    }
                    
                    Text(entry?.text ?? "CoinCurrently")
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .minimumScaleFactor(0.8)
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
        RectangularLockScreenNewsWidget()
    }
}
