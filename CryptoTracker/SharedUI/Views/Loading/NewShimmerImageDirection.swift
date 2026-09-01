//
//  NewShimmeringImage.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/1/25.
//

import SwiftUI

enum ChangeSize {
    case extraSmall
    case small
    case medium
    case large
    
    var triangleSize: CGFloat {
        switch self {
        case .extraSmall, .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 20
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .extraSmall:
            return 12
        case .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 20
        }
    }
}

struct NewShimmerImageDirection: View {
#if IS_WIDGET
    @Environment(\.colorScheme) var scheme
#endif

    @ScaledMetric private var scale: CGFloat = 1
    
    let change: Double?
    var size: ChangeSize = .large
    let isDownloading: Bool
    
    @State private var show = false
    
    var body: some View {
        ZStack {
            (change?.changeImage ?? .trendStill)
                .resizable()
                .foregroundStyle(directionColor)
            
            if isDownloading {
                tempImage
            }
        }
        .frame(width: size.triangleSize * min(scale, 1.5), height: size.triangleSize * min(scale, 1.5))
        .animation(isDownloading ? .linear(duration: 2) : .none, value: show)
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
    
    private var directionColor: Color {
#if IS_WIDGET
        change?.changeColor(for: scheme) ?? Color.shimmeringBackground(for: scheme).opacity(0.15)
#else
        change?.changeColor ?? Color.shimmeringBackground.opacity(0.15)
#endif
    }
    
    private var shimmerColor: Color {
#if IS_WIDGET
        Color.onSurface(for: scheme).opacity(0.25)
#else
        Color.onSurface.opacity(0.25)
#endif
    }
    
    private var tempImage: some View {
        Image.trendStill
            .resizable()
            .foregroundStyle(shimmerColor)
            .mask(
                Capsule()
                    .fill(LinearGradient(gradient: .init(colors: [.clear, shimmerColor, .clear]), startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.init(degrees: 30))
                    .offset(x: show ? -360 : 360)
            )
    }
}
