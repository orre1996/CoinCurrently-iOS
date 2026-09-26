//
//  CircularAppShortcutWidget.swift
//  CryptoWidgetExtension
//

import SwiftUI
import WidgetKit

struct CircularAppShortcutWidget: View {
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
       // if let url = URL(string: .appName) {
           // GeometryReader { proxy in
              //  let side = min(proxy.size.width, proxy.size.height) * 0.55
                
                //ZStack {
                    //AccessoryWidgetBackground()
                    
                    Image("iconNoBackground")
                        //.renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                       // .foregroundStyle(Color.onSurfaceDimmest(for: scheme))
              //  }
           // }
            .widgetBackground(Color.clear)
          //  .accessibilityLabel("Open CoinCurrently")
          //  .widgetURL(url)
       // }
    }
}
