//
//  NewShimmeringText.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/31/25.
//

import SwiftUI

#if IS_APP || IS_WATCH
struct NewShimmeringText: View {
    let text: String
    let isDownloading: Bool
    var useNumericContentTransition: Bool = false
    
    @State private var show = false
    @State private var offset: CGFloat = 360
    
    var body: some View {
        Text(text)
            .if(useNumericContentTransition) { view in
                view.contentTransition(.numericText())
            }
            .redacted(reason: isDownloading ? .placeholder : [])
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .topLeading) {
                if isDownloading {
                    tempText
                }
            }
        .onAppear {
            show.toggle()
            
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                if isDownloading {
                    Task { @MainActor in
                        show.toggle()
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    private var tempText: some View {
        Text(text)
            .foregroundStyle(Color.shimmeringBackground)
            .redacted(reason: isDownloading ? .placeholder : [])
            .fixedSize(horizontal: false, vertical: true)
            .cornerRadius(3)
            .mask(
                Capsule()
                    .fill(LinearGradient(gradient: .init(colors: [.clear, .onSurface, .clear]), startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.init(degrees: 30))
                    .offset(x: show ? -360 : 360)
            )
            .animation(.linear(duration: 2), value: show)
        
    }
}
#elseif IS_WIDGET
struct NewShimmeringText: View {
    @Environment(\.colorScheme) var scheme

    let text: String
    let isDownloading: Bool
    var useNumericContentTransition: Bool = false
    
    @State private var show = false
    @State private var offset: CGFloat = 360
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .redacted(reason: isDownloading ? .placeholder : [])
            
            if isDownloading {
                tempText
            }
        }
        .onAppear {
            show.toggle()
            
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                if isDownloading {
                    Task { @MainActor in
                        show.toggle()
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    private var tempText: some View {
        Text(text)
            .foregroundStyle(Color.shimmeringBackground(for: scheme))
            .redacted(reason: isDownloading ? .placeholder : [])
            .fixedSize(horizontal: false, vertical: true)
            .cornerRadius(3)
            .mask(
                Capsule()
                    .fill(LinearGradient(gradient: .init(colors: [.clear, Color.primary, .clear]), startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.init(degrees: 30))
                    .offset(x: show ? -360 : 360)
            )
            .animation(.linear(duration: 2), value: show)
        
    }
}
#endif
