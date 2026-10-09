//
//  SnackbarView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-10-08.
//

import SwiftUI

struct SnackbarView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @ScaledMetric private var scale: CGFloat = 1
    
    @Binding var showSnackBar: Bool
    @Binding var message: String
    @Binding var buttonTitle: String
    
    var type: SnackbarTypes = .success
    var isTabbarHidden: Bool
    var isOverlayShowing: Bool
    @Binding var isPresented: Bool
    @Binding var reportedHeight: CGFloat
    var overlayPressed: () -> Void
    var buttonAction: () -> Void
    
    @State private var canDrag = true
    @State private var offset: CGFloat = 600
    @State private var timer: Timer?
    @State private var buttonTimer: Timer?
    @State private var viewHeight: CGFloat = 0
    @State private var isSnackbarVisible = false
    
    @AccessibilityFocusState private var isSnackbarFocused: Bool
    
    private var icon: Image {
        type == .success ? .checkCircle : .xCircle
    }
    
    private var iconColor: Color {
        type == .success ? .trendUp : .trendDown
    }
    
    private var snackbarAccessibilityLabel: String {
        guard !buttonTitle.isEmpty else {
            return message
        }
        
        return "\(message), \(buttonTitle)"
    }
    
    private var ios26Offset: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }
    
    var body: some View {
        snackBarView
            .offset(
                y: offset
                + (isTabbarHidden ? UITabBarController().height + (ios26Offset ? 0 : 16) : 0)
                + (ios26Offset ? 32 : 0)
            )
            .animation(.default, value: isTabbarHidden)
            .padding(16)
            .gesture(dragGesture)
            .onTapGesture(perform: dismissSnackBar)
            .onChange(of: showSnackBar) { _, _ in
                showAnimatedSnackBar()
            }
            .overlay {
                ZStack {
                    if isOverlayShowing {
                        Color.overlayBackground.opacity(0.7)
                    }
                }
            }
    }
    
    private var snackBarView: some View {
        HStack(spacing: 16) {
            icon
                .resizable()
                .foregroundStyle(iconColor)
                .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                .accessibilityHidden(true)
            
            Text(message)
                .font(.satoshiMedium(16))
                .foregroundStyle(Color.onSurface)
            
            if !buttonTitle.isEmpty {
                Button(action: {
                    if canDrag {
                        buttonAction()
                        dismissSnackBar()
                    }
                }, label: {
                    Text(buttonTitle)
                        .font(.satoshiMedium(16))
                        .foregroundStyle(Color.primary)
                })
                .accessibilityHidden(true)
            }
        }
        .padding(16)
        .background(Color.surfaceContainerHighest)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snackbarAccessibilityLabel)
        .accessibilityFocused($isSnackbarFocused)
        .accessibilityAction {
            guard canDrag, !buttonTitle.isEmpty else { return }
            
            buttonAction()
            dismissSnackBar()
        }
        .accessibilityHidden(!isSnackbarVisible)
        .readSize {
            viewHeight = $0.height
            reportedHeight = $0.height
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { _ in
                guard !isOverlayShowing else { return }
                
                dismissSnackBar()
            }
    }
    
    private func dismissSnackBar() {
        guard canDrag && !isOverlayShowing else { return }
        
        canDrag = false
        timer?.invalidate()
        isSnackbarFocused = false
        
        withAnimation(.easeIn(duration: SnackbarConstants.animationDuration)) {
            offset = UITabBarController().height + viewHeight + 32
        }
        
        buttonTimer = Timer.scheduledTimer(withTimeInterval: SnackbarConstants.animationDuration, repeats: false) { _ in
            Task { @MainActor in
                message = ""
                buttonTitle = ""
                canDrag = true
                isSnackbarVisible = false
                isPresented = false
                reportedHeight = 0
            }
        }
    }
    
    private func showAnimatedSnackBar() {
        timer?.invalidate()
        buttonTimer?.invalidate()
        
        offset = UITabBarController().height + viewHeight + 32
        isSnackbarVisible = true
        isPresented = true
        
        withAnimation(.easeOut(duration: SnackbarConstants.animationDuration)) {
            offset = -UITabBarController().height
        }
        
        asyncMain(delay: 0.85) {
            isSnackbarFocused = true
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: SnackbarConstants.displayDuration, repeats: false) { _ in
            Task { @MainActor in
                isSnackbarFocused = false
                
                withAnimation(.easeIn(duration: SnackbarConstants.animationDuration)) {
                    offset = UITabBarController().height + viewHeight + 32
                }
                
                canDrag = false
                buttonTimer = Timer.scheduledTimer(withTimeInterval: SnackbarConstants.animationDuration, repeats: false) { _ in
                    Task { @MainActor in
                        message = ""
                        buttonTitle = ""
                        canDrag = true
                        isSnackbarVisible = false
                        isPresented = false
                        reportedHeight = 0
                    }
                }
            }
        }
    }
}
