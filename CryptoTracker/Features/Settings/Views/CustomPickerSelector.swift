//
//  CustomPickerSelector.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-14.
//

import SwiftUI

struct CustomPickerSelector: View {
    @ScaledMetric private var scale: CGFloat = 1

    @State var selectedIndex = 0
    @State private var widestString: CGFloat = 0
    @State private var tallestString: CGFloat = 0
    
    let texts: [String]
    var accessibilityTexts: [String] = []
    var font: Font = .satoshiRegular(14)
    var uiFont: UIFont = .satoshiRegular(14)
    var withGradientBackground = false
    var disabledIndices: [Int] = []
    var canScaleDown: Bool = false
    var inverseColors: Bool = false
    var doubleVerticalPadding: Bool = false
    var setHeight: Bool = false
    var extraSmall: Bool = false
    var minWidth: CGFloat?
    var oneRow: Bool = true
    var valueChanged: (Int) -> () = { _ in }
    
    let textFocused = Color.inverseOnSurface
    
    @Namespace private var namespace
    
    var body: some View {
        
        PickerStack(oneRow: oneRow) {
            
            ForEach(0..<texts.count, id: \.self) { index in
                
                Button(action: { 
                    valueChanged(index)
                    
                    if index != selectedIndex {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    
                    withAnimation {
                        selectedIndex = index
                    }
                }, label: {
                    Text(texts[safely: index] ?? "")
                        .foregroundColor(getTextColor(index: index))
                        .lineLimit(1)
                        .if(setHeight) { view in
                            view.frame(height: tallestString)
                        }
                        .padding(.vertical, doubleVerticalPadding ? 16 : 8)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("\(accessibilityTexts[safely: index] ?? texts[safely: index] ?? "").")
                        .accessibilityAddTraits(selectedIndex == index ? [.isSelected] : [])
                        .frame(minWidth: minWidth ?? widestString)
                        .background(
                            ZStack {
                                if index == selectedIndex {
                                    (inverseColors ? Color.inverseSurface : Color.onSurface)
                                        .cornerRadius(4)
                                        .padding(.vertical, 4)
                                        .matchedGeometryEffect(id: "position", in: namespace)
                                }
                            }
                        )
                })
            }
        }
        .font(font)
        .if(canScaleDown) { view in 
            view.minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 4)
        .allowsHitTesting(disabledIndices.isEmpty)
        .if(!withGradientBackground) { view in
            view.background(inverseColors ? Color.onSurface : textFocused)
                .cornerRadius(8)
        }
        /*.if(withGradientBackground) { view in
            view.modifier(CardBackground(hasPadding: false))
        }*/
#if IS_APP
        .onUIKitWillAppear {
            setBiggestString()
        }
        .onAppDidBecomeActive {
            setBiggestString()
        }
#else
        .onAppear {
            setBiggestString()
        }
#endif
    }
    
    func setBiggestString() {
        let dynamicFont = UIFontMetrics.default.scaledFont(for: uiFont, maximumPointSize: 30)
        widestString = max(48, (texts.map({ $0.widthOfString(usingFont: dynamicFont) }).max() ?? 42) + 8)
        tallestString = max(20, (texts.map({ $0.heightOfString(usingFont: dynamicFont, withDynamicFont: false) }).max() ?? 20))
    }

    func getTextColor(index: Int) -> Color {
        if !disabledIndices.isEmpty && !disabledIndices.contains(index) {
            return inverseColors ? .onSurface : textFocused
        } else if disabledIndices.contains(index) {
            return .trendDown
        } else if index == selectedIndex {
            return inverseColors ? .onSurface : textFocused
        } else {
            return .trendUp
        }
    }
}

private struct PickerStack<Content>: View where Content: View {
    let content: Content
    let oneRow: Bool

    init(oneRow: Bool,
         @ViewBuilder content: () -> Content) {
        self.oneRow = oneRow
        self.content = content()
    }

    var body: some View {
        if oneRow {
            HStack(spacing: 8) { content }
        } else {
            OverflowLayout(spacing: 8) { content }
        }
    }
}
