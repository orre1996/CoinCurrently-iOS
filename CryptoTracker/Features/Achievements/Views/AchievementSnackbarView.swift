//
//  AchievementSnackbarView.swift
//  CoinCurrently
//

import SwiftUI

struct AchievementSnackbarView: View {
    @ScaledMetric private var scale: CGFloat = 1

    var snackbarTrigger: Int
    @Binding var achievementTitle: String
    @Binding var levelName: String

    var isTabbarHidden: Bool
    var standardSnackbarIsVisible: Bool
    @Binding var isPresented: Bool
    @Binding var reportedHeight: CGFloat

    @State private var canDrag = true
    @State private var offset: CGFloat = 600
    @State private var timer: Timer?
    @State private var dismissTimer: Timer?
    @State private var viewHeight: CGFloat = 0
    @State private var isSnackbarVisible = false
    @State private var animatedProgress: Double = 0

    @AccessibilityFocusState private var isSnackbarFocused: Bool

    private var ios26Offset: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }

    private var accessibilityLabel: String {
        "Achievement unlocked, \(achievementTitle), \(levelName)"
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
            .onChange(of: snackbarTrigger) { _, trigger in
                guard trigger > 0 else { return }
                showAnimatedSnackBar()
            }
            .onChange(of: standardSnackbarIsVisible) { _, isVisible in
                guard isSnackbarVisible else { return }

                if isVisible {
                    timer?.invalidate()
                } else {
                    timer?.invalidate()
                    dismissSnackBar()
                }
            }
    }

    private var snackBarView: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 36 * min(scale, 1.5), height: 36 * min(scale, 1.5))

                Image.checkmark
                    .font(.system(size: 16 * min(scale, 1.5), weight: .bold))
                    .foregroundStyle(Color.primary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievementTitle)
                        .font(.satoshiBold(15))
                        .foregroundStyle(Color.onSurface)
                        .lineLimit(1)

                    Text(levelName)
                        .font(.satoshiMedium(13))
                        .foregroundStyle(Color.onSurfaceDim)
                        .lineLimit(1)
                }

                CustomProgressBarView(
                    progress: animatedProgress,
                    foregroundColor: .primary,
                    backgroundColor: .surfaceContainerHigh,
                    height: 5
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityFocused($isSnackbarFocused)
        .accessibilityHidden(!isSnackbarVisible)
        .readSize {
            viewHeight = $0.height
            reportedHeight = $0.height
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { _ in
                dismissSnackBar()
            }
    }

    private func dismissSnackBar() {
        guard canDrag else { return }

        canDrag = false
        timer?.invalidate()
        isSnackbarFocused = false

        withAnimation(.easeIn(duration: SnackBarConstants.animationDuration)) {
            isPresented = false
            offset = hiddenOffset
        }

        dismissTimer = Timer.scheduledTimer(withTimeInterval: SnackBarConstants.animationDuration, repeats: false) { _ in
            Task { @MainActor in
                resetContent()
            }
        }
    }

    private func showAnimatedSnackBar() {
        timer?.invalidate()
        dismissTimer?.invalidate()

        animatedProgress = 0
        offset = hiddenOffset
        isSnackbarVisible = true
        canDrag = true

        withAnimation(.easeOut(duration: SnackBarConstants.animationDuration)) {
            isPresented = true
            offset = visibleOffset
        }

        asyncMain(delay: 0.85) {
            withAnimation(.easeOut(duration: 0.9)) {
                animatedProgress = 1
            }
        }

        asyncMain(delay: 0.85) {
            isSnackbarFocused = true
        }

        scheduleAutoDismiss()
    }

    private func scheduleAutoDismiss() {
        timer?.invalidate()

        guard !standardSnackbarIsVisible else { return }

        timer = Timer.scheduledTimer(withTimeInterval: SnackBarConstants.displayDuration, repeats: false) { _ in
            Task { @MainActor in
                dismissSnackBar()
            }
        }
    }

    private var hiddenOffset: CGFloat {
        UITabBarController().height + viewHeight + 32
    }

    private var visibleOffset: CGFloat {
        -UITabBarController().height
    }

    private func resetContent() {
        achievementTitle = ""
        levelName = ""
        animatedProgress = 0
        canDrag = true
        isSnackbarVisible = false
        reportedHeight = 0
    }
}
