//
//  LockedToggle.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 3/24/26.
//

import SwiftUI

struct LockedToggle: View {
    let isOn: Bool
    let action: () -> Void
    
    @ScaledMetric private var scale: CGFloat = 1
    
    private var toggleScale: CGFloat { min(scale, 1.5) }
    private var trackWidth: CGFloat { 54 * toggleScale }
    private var trackHeight: CGFloat { 32 * toggleScale }
    private var thumbSize: CGFloat { 24 * toggleScale }
    private var thumbPadding: CGFloat { 3 * toggleScale }
    private var thumbOffset: CGFloat { (trackWidth - thumbPadding * 2 - thumbSize) / 2 }

    var body: some View {
        Capsule()
            .fill(isOn ? Color.primary : Color.surfaceContainerLowest)
            .frame(width: trackWidth, height: trackHeight)
            .overlay(
                Circle()
                    .fill(isOn ? Color.onPrimary : Color.onSurfaceDimmer)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(radius: 1, x: 0, y: 1)
                    .padding(thumbPadding)
                    .offset(x: isOn ? thumbOffset : -thumbOffset)
            )
            .onTapGesture {
                action()
            }
            .animation(Animation.easeInOut(duration: 0.2), value: isOn)
            .accessibilityLabel(Localization.format(
                "Switch button, %@",
                Localization.string(isOn ? "checked" : "unchecked")
            ))
    }
}
