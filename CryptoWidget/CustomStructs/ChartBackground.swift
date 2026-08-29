//
//  ChartBackground.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-26.
//

import SwiftUI

struct ChartBackground: View {
    @Binding var biggestValue: CGSize
    
    let values: [String?]
    
    var body: some View {
        let widestString = (values.max(by: { $0?.count ?? 0 < $1?.count ?? 0 }) ?? "000") ?? "000"
        
        VStack(spacing: 0) {
            ForEach(0..<values.count, id: \.self) { index in
                let value = values.reversed()[safely: index] ?? "000"
                
                HStack(spacing: 4) {
                    Separator()

                    MinimumTextSize(text: widestString, alignment: .leading) {
                        NewShimmeringText(
                            text: value ?? "000",
                            isDownloading: value == nil
                        )
                    }
                    .readSize {
                        if $0.width > 0 {
                            biggestValue = CGSize(width: $0.width + 4, height: $0.height)
                        }
                    }
                }
                
                if index != values.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .accessibilityHidden(true)
    }
}
