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
            Text(inlineText)
                .widgetURL(url)
        }
    }

    private var inlineText: String {
        let item = fearGreedModel?.data?.first
        let value = item?.value ?? "0"
        let status = item?.value_classification ?? ""
        guard !status.isEmpty else { return "\(value)/100" }
        return "\(value)/100 \(status)"
    }
}
