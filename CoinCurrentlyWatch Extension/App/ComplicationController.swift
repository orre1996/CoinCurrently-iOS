//
//  ComplicationController.swift
//  CoinCurrentlyWatch Extension
//
//  Created by Oscar Berggren on 2021-08-23.
//

import ClockKit
import SwiftUI


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    private let dataStore = CryptoDataStore()
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "CoinCurrently", supportedFamilies: [
                .graphicRectangular,
                .modularLarge,
                .graphicCorner,
                .graphicCircular,
                .extraLarge,
                .graphicExtraLarge,
                .circularSmall,
            ])
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    
    // MARK: - Timeline Configuration
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        
        guard let currency = dataStore.lastCrypto, let template = makeTemplate(currency: currency, complication: complication) else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(date: Date().addingTimeInterval(60 * 3), complicationTemplate: template)
        handler(entry)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        let template = makeTemplate(currency: CurrencyDataModel(symbol: "CNCR", name: "CoinCurrently", market_data: MarketData(current_price: Dictionary(
            uniqueKeysWithValues: CurrencyModel.allCurrencies.map {
                ($0.code, 0.0)
            }
        ), price_change_percentage_7d: 0)), complication: complication)
        handler(template)
    }
}

extension ComplicationController {
    func makeTemplate(
        currency: CurrencyDataModel?,
        complication: CLKComplication
    ) -> CLKComplicationTemplate? {
        switch complication.family {
            
            
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: CLKSimpleTextProvider(text: currency?.symbol?.uppercased() ?? ""), line2TextProvider: CLKSimpleTextProvider(format: currency?.market_data?.current_price?.getConvertedCurrency()?.formatCurrency(threshold: .thousand) ?? ""))
            
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularView(
                VStack(spacing: 0) {
                    Text(currency?.symbol?.uppercased() ?? "")
                        .font(.satoshiBold(10))
                        .padding(.horizontal, 2)
                    
                    let currentPrice = currency?.market_data?.current_price?.getConvertedCurrency() ?? 0
                    Text(currentPrice.formatCurrency(
                        threshold: .hundredThousand,
                        currency: CurrencyModel(currency: "", code: "", symbol: "", suffix: true),
                        maxDecimals: currentPrice < 100 ? 4 : 0
                    ))
                        .font(.satoshiBold(12))
                    
                    let symbol = currency?.market_data?.price_change_percentage_7d?.roundTo(places: 2) ?? 0 < 0 ? "" : "+"
                    let change = currency?.market_data?.price_change_percentage_7d ?? 0.00
                    let decimals = abs(change.roundTo(places: 2)) >= 100.0 ? 1 : 2
                    let secondDecimals = "%.\(decimals)f"
                    let formattedChange = "\(String(format: secondDecimals, currency?.market_data?.price_change_percentage_7d ?? 0.00))"
                    Text("\(symbol)\(formattedChange)%")
                        .font(.satoshiMedium(10))
                        .padding(.horizontal, 7)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(Color.onSurface)
            )
            
        case .graphicCorner:
            
            let symbol = currency?.market_data?.price_change_percentage_7d?.roundTo(places: 2) ?? 0 < 0 ? "" : "+"
            
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: CLKSimpleTextProvider(text: "\(currency?.market_data?.current_price?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.thousand) ?? "")  \(symbol)\(currency?.market_data?.price_change_percentage_7d?.formatted(.number.precision(.fractionLength(2))) ?? "")%"),
                outerTextProvider: CLKSimpleTextProvider(text: currency?.symbol?.uppercased() ?? ""))
            
        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKTimeTextProvider(format:"\(currency?.name ?? "CoinCurrently")"),
                body1TextProvider: CLKTextProvider(format: "\(currency?.market_data?.current_price?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.none) ?? "")\n7d:  \(currency?.market_data?.price_change_percentage_7d?.formatted(.number.precision(.fractionLength(2))) ?? "")%"))
            
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularFullView(ComplicationView(currentCurrency: currency))
            
        case .graphicExtraLarge:
            return CLKComplicationTemplateGraphicExtraLargeCircularView(
                VStack(spacing: 0) {
                    
                    Text(currency?.name ?? "CoinCurrently")
                        .font(.satoshiBold(22))
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 5)
                        .foregroundColor(Color.onSurface)
                    
                    Text("\(currency?.market_data?.current_price?.getConvertedCurrency()?.formatCurrency(threshold: FormattingThreshold.thousand) ?? "")")
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.onSurface)
                        .font(.semiboldWidget18)
                    
                    PriceChangePercentView(
                        change: currency?.market_data?.price_change_percentage_7d,
                        accessibleTimeframe: "7 days",
                        isDownloading: currency == nil
                    )
                }
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .preferredColorScheme(.dark)
            )
            
        default:
            return nil
        }
    }
}

