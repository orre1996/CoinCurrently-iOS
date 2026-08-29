//
//  ShimmeringImage.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-10-28.
//

import SwiftUI

#if IS_APP || IS_WATCH
import Combine
import Kingfisher

enum ImageScaleMode {
    case fit
    case fill
}

extension View {
    @ViewBuilder
    func scaledTo(mode: ImageScaleMode) -> some View {
        switch mode {
        case .fit:
            scaledToFit()
        case .fill:
            scaledToFill()
        }
    }
}

@MainActor
struct ShimmeringImage: View {
    let imageUrl: String?
    let downloading: Bool
    let size: CGFloat
    var radius: CGFloat = 8
    var width: CGFloat?
    var showShimmer: Bool = true
    var scaleMode: ImageScaleMode = .fit

    @State private var hasImage = false
    @State private var show = false
    @State private var imageDownloaded = false
    @State private var cancellable: AnyCancellable?
    
    var body: some View {
        ZStack {
            if hasImage && !downloading, let urlString = imageUrl, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder { placeholderImage }
                    .onSuccess { _ in
                        imageDownloaded = true
                    }
                    .resizable()
                    .scaledTo(mode: scaleMode)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: radius))
            } else {
                placeholderImage
            }
        }
        .task {
            guard showShimmer else { return }
            
            show.toggle()
            
            cancellable = Timer.publish(every: 2.5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    Task { @MainActor in
                        if !imageDownloaded {
                            show.toggle()
                        } else {
                            cancellable?.cancel()
                        }
                    }
                }
        }
        .task {
            guard let imageUrl, !imageUrl.isEmpty else {
                hasImage = false
                return
            }

            hasImage = true
        }
        .onChange(of: imageUrl) { _, url in
            guard let url else {
                hasImage = false
                return
            }

            if !url.isEmpty {
                hasImage = true
            } else {
                hasImage = false
            }
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color.shimmeringBackground.opacity(0.15)
                .frame(width: width ?? size, height: size, alignment: .center)
                .scaledToFit()
                .cornerRadius(radius)
                .clipShape(RoundedRectangle(cornerRadius: radius))
            
            Color.onSurface.opacity(0.25)
                .frame(width: width ?? size, height: size, alignment: .center)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .mask(
                    Capsule()
                        .fill(LinearGradient(gradient: .init(colors: [.clear, .onSurface, .clear]), startPoint: .top, endPoint: .bottom))
                        .rotationEffect(.init(degrees: 30))
                        .offset(x: show ? -360 : 360)
                )
                .animation(.linear(duration: 2), value: show)
                .cornerRadius(radius)
        }
    }
}

struct ShimmeringImageWithUIImage: View {
    let image: UIImage?
    let downloading: Bool
    let size: CGFloat
    @State var show = false
    
    var radius: CGFloat = 8

    var body: some View {
        if !downloading {
            Image(uiImage: image ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size, alignment: .center)
        } else {
            ZStack {
                Color.shimmeringBackground.opacity(0.15)
                    .frame(width: size, height: size, alignment: .center)
                    .scaledToFit()
                    .cornerRadius(radius)
                
                Color.onSurface.opacity(0.25)
                    .frame(width: size, height: size, alignment: .center)
                    .scaledToFit()
                    .mask(
                        Capsule()
                            .fill(LinearGradient(gradient: .init(colors: [.clear, .onSurface, .clear]), startPoint: .top, endPoint: .bottom))
                            .rotationEffect(.init(degrees: 30))
                            .offset(x: show ? 360 : -360)
                    )
                    .cornerRadius(radius)
                    .animation(Animation.linear(duration: 2), value: show)
                    .onAppear {
                        show.toggle()

                        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                            if downloading {
                                Task { @MainActor in
                                    show.toggle()
                                }
                            } else {
                                timer.invalidate()
                            }
                        }
                    }
            }
        }
    }
}

#elseif IS_WIDGET

struct ShimmeringImageWithUIImage: View {
    @Environment(\.colorScheme) var scheme

    let image: UIImage?
    let downloading: Bool
    let size: CGFloat
    @State var show = false

    var radius: CGFloat = 8

    var body: some View {
        if !downloading {
            Image(uiImage: image ?? UIImage())
                .resizable()
                .widgetAccentedRenderingMode(.desaturated)
                .scaledToFit()
                .frame(width: size, height: size, alignment: .center)
        } else {
            ZStack {
                Color.shimmeringBackground(for: scheme).opacity(0.15)
                    .frame(width: size, height: size, alignment: .center)
                    .scaledToFit()
                    .cornerRadius(radius)

                Color.onSurface(for: scheme).opacity(0.25)
                    .frame(width: size, height: size, alignment: .center)
                    .scaledToFit()
                    .mask(
                        Capsule()
                            .fill(LinearGradient(gradient: .init(colors: [.clear, Color.primary, .clear]), startPoint: .top, endPoint: .bottom))
                            .rotationEffect(.init(degrees: 30))
                            .offset(x: show ? 360 : -360)
                    )
                    .cornerRadius(radius)
                    .animation(Animation.linear(duration: 2), value: show)
                    .onAppear {
                        show.toggle()

                        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                            if downloading {
                                Task { @MainActor in
                                    show.toggle()
                                }
                            } else {
                                timer.invalidate()
                            }
                        }
                    }
            }
        }
    }
}

#endif
