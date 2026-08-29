//
//  InlineFearGreedWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2023-09-09.
//

import SwiftUI

struct InlineFearGreedWidget: View {
    let fearGreedModel: FearGreed?
    
    var body: some View {
        if let url = URL(string: "fearGreed") {
            Text("Fear and Greed: \(fearGreedModel?.data?.first?.value ?? "0")/100")
                .widgetURL(url)
        }
    }
}
