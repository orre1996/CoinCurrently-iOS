//
//  ChartButtonsView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/1/25.
//

import SwiftUI

struct ChartButtonsView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
    
    @ScaledMetric private var scale: CGFloat = 1
    @State private var voiceOverChartTypeIndex = 0
    
    let fromScreen: ScreenLabel
    let selectedGraphType: ChartTypes
    let isCandleChartEnabled: Bool
    var inCompareScreen: Bool = false
    var isAlwaysSelectable: Bool = false
    let imageCase: ImageCase
    let chartTypeAction: (ChartTypes) -> Void
    let toggleCandleChart: () async -> Void
    
    private var chartTypeOptions: [(title: String, type: ChartTypes)] {
        switch fromScreen {
        case .globalMarket:
            return [
                ("Volume", .volume),
                ("Market Cap", .mktCap)
            ]
        default:
            return [
                ("Price", .price),
                ("Volume", .volume),
                ("Market Cap", .mktCap)
            ]
        }
    }
    
    private var selectableChartTypes: [(title: String, type: ChartTypes)] {
        chartTypeOptions.filter { !isChartTypeDisabled($0.type) }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            chartTypeButtons
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !inCompareScreen {
                candleChartToggleButton
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .optionalGlassEffectContainer(spacing: 8)
        .padding(
            EdgeInsets(
                top: 32,
                leading: 16,
                bottom: 16,
                trailing: 16
            )
        )
    }
    
    @ViewBuilder
    private var chartTypeButtons: some View {
        OverflowLayout(spacing: 8) {
            ForEach(chartTypeOptions, id: \.type) { option in
                chartButton(
                    title: option.title,
                    isSelected: isChartTypeSelected(option.type),
                    disabled: isChartTypeDisabled(option.type),
                    action: {
                        selectChartType(option.type)
                    }
                )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            syncVoiceOverChartTypeIndex()
        }
        .onChange(of: selectedGraphType) { _, _ in
            syncVoiceOverChartTypeIndex()
        }
        .onChange(of: isCandleChartEnabled) { _, _ in
            syncVoiceOverChartTypeIndex()
        }
        .if(accessibilityVoiceOverEnabled) { view in
            view
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Chart type selector. Swipe up or down to change chart type.")
                .accessibilityValue(selectedChartTypeAccessibilityValue)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        selectAdjacentChartType(offset: 1)
                    case .decrement:
                        selectAdjacentChartType(offset: -1)
                    @unknown default:
                        break
                    }
                }
        }
    }
    
    private func isChartTypeSelected(_ type: ChartTypes) -> Bool {
        switch type {
        case .price:
            selectedGraphType == .price || (isCandleChartEnabled && !isAlwaysSelectable)
        case .volume:
            selectedGraphType == .volume && (!isCandleChartEnabled || isAlwaysSelectable)
        case .mktCap:
            selectedGraphType == .mktCap && (!isCandleChartEnabled || isAlwaysSelectable)
        }
    }
    
    private func isChartTypeDisabled(_ type: ChartTypes) -> Bool {
        switch type {
        case .price:
            false
        case .volume, .mktCap:
            isCandleChartEnabled && !isAlwaysSelectable
        }
    }
    
    private var selectedChartTypeAccessibilityValue: String {
        let option = selectableChartTypes[safely: voiceOverChartTypeIndex]
        let title = option?.title ?? ""
        let count = selectableChartTypes.count
        return "Chart type \(voiceOverChartTypeIndex + 1) of \(count), \(title)."
    }
    
    private func syncVoiceOverChartTypeIndex() {
        if let index = selectableChartTypes.firstIndex(where: { $0.type == selectedGraphType }) {
            voiceOverChartTypeIndex = index
        } else {
            voiceOverChartTypeIndex = 0
        }
    }
    
    private func selectAdjacentChartType(offset: Int) {
        let newIndex = voiceOverChartTypeIndex + offset
        guard selectableChartTypes.indices.contains(newIndex) else { return }
        
        let newType = selectableChartTypes[newIndex].type
        guard newType != selectedGraphType else { return }
        
        voiceOverChartTypeIndex = newIndex
        selectChartType(newType)
    }
    
    private func selectChartType(_ type: ChartTypes) {
        if type != selectedGraphType {
            AnalyticsManager.shared.log(
                ChartTypeChanged(fromScreen: fromScreen, chartType: type)
            )
        }
        chartTypeAction(type)
    }
    
    private func chartButton(
        title: String,
        isSelected: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.onPrimary.opacity(disabled ? 0.35 : 1) : Color.onSurfaceContainer.opacity(disabled ? 0.35 : 1))
                .font(.satoshiMedium(16))
                .padding(
                    EdgeInsets(
                        top: 12,
                        leading: 16,
                        bottom: 12,
                        trailing: 16
                    )
                )
                .optionalGlassEffect(
                    color: isSelected ? Color.primary.opacity(disabled ? 0.35 : 1) : Color.surfaceContainerHigh.opacity(disabled ? 0.35 : 1),
                    radius: 1000,
                    isInteractive: true
                )
        })
        .disabled(disabled)
        .accessibilityHidden(accessibilityVoiceOverEnabled)
        .accessibilityLabel("Chart type: \(title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var candleChartToggleButton: some View {
        Button(action: {
            Task {
                await toggleCandleChart()
            }
        }, label: {
            Group {
                if case let .image(string) = imageCase {
                    ShimmeringImage(
                        imageUrl: string,
                        downloading: string == nil,
                        size: 24 * min(scale, 1.5)
                    )
                    .clipShape(Circle())
                } else if case let .fixed(image) = imageCase {
                    image
                        .resizable()
                } else if case let .text(text) = imageCase {
                    Text(text)
                        .font(.satoshiBold(18))
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(width: 24 * min(1.5, scale), height: 24 * min(1.5, scale))
            .foregroundStyle(Color.onSurface)
            .padding(12)
            .optionalGlassEffect(
                color: Color.surfaceContainerHigh,
                radius: 1000,
                isInteractive: true
            )
            .accessibilityLabel(candleChartToggleAccessibilityLabel)
            .accessibilityAddTraits(.isToggle)
        })
    }
    
    private var candleChartToggleAccessibilityLabel: String {
        if fromScreen == .nftDetail {
            return isCandleChartEnabled ? "Switch to Fiat chart" : "Switch to NFT chart"
        }
        return "Switch to \(isCandleChartEnabled ? "line chart" : "candle chart")"
    }
}
