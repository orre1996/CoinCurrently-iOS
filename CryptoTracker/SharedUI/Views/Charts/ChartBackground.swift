//
//  ChartBackground.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-26.
//

import SwiftUI

struct ChartBackground: View {
    @Binding var biggestValue: CGSize
    @State private var measurePass = 0
    
    let values: [String?]
    
    private var displayedValues: [String?] {
        #if IS_WATCH
        guard values.count > 3 else { return values }
        return (0..<3).map { step in
            let index = Int((Double(values.count - 1) * Double(step) / 2).rounded())
            return values[safely: index] ?? nil
        }
        #else
        values
        #endif
    }
    
    private var widestString: String {
        let font = UIFont.satoshiBold(12)
        return displayedValues
            .map { $0 ?? "000" }
            .max { $0.widthOfString(usingFont: font) < $1.widthOfString(usingFont: font) } ?? "000"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<displayedValues.count, id: \.self) { index in
                let value = displayedValues.reversed()[safely: index] ?? "000"
                
                HStack(spacing: 4) {
                    Separator()

                    MinimumTextSize(text: widestString, alignment: .leading) {
                        ShimmeringText(
                            text: value ?? "000",
                            isDownloading: value == nil
                        )
                    }
                    .readSize {
                        let width = $0.width + 4
                        guard $0.width > 0, width > biggestValue.width else { return }
                        biggestValue = CGSize(width: width, height: $0.height)
                    }
                }
                
                if index != displayedValues.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .id(measurePass)
        .onChange(of: values) {
            biggestValue.width = 0
            measurePass += 1
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .foregroundStyle(Color.onSurfaceDimmer)
        .font(.satoshiBold(12))
        .accessibilityHidden(true)
    }
}
