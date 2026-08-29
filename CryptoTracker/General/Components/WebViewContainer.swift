//
//  NewsCollectionView.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-31.
//

import SwiftUI
import WebKit

struct WebViewContainer: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    
    @ScaledMetric private var scale: CGFloat = 1
    
    let url: String
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandler()
                .padding(
                    EdgeInsets(
                        top: 16,
                        leading: 0,
                        bottom: 24,
                        trailing: 0
                    )
                )

            HStack(spacing: 0) {
                Button(action: {
                    if let url = URL(string: url) {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    Image.external
                        .resizable()
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                        .padding(12)
                })
                .optionalGlassEffect(
                    color: Color.surfaceContainerHigh,
                    radius: 1000,
                    isInteractive: true
                )
                
                Spacer(minLength: 16)
                
                CloseButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
            
            WebView(url: url)
        }
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea()
    }
}

struct WebView: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> some UIView {
        guard let url = URL(string: url) else { return WKWebView() }
        
        let request = URLRequest(url: url)
        let webview = WKWebView()
        webview.load(request)
        return webview
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
