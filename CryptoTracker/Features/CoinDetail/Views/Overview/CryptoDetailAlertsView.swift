//
//  CurrencyConverterView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 5/13/25.
//

import SwiftUI

struct CryptoDetailAlertsView: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    let cryptoDetailModel: CurrencyDataModel?
    let alerts: [AlertCoin]?
    let addNewAlert: () -> Void
    let deleteAlert: (AlertCoin) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerView
            
            LazyVStack(spacing: 8) {
                if let alerts {
                    if alerts.isEmpty {
                        EmptyContent(
                            title: Localization.string("No price alerts yet"),
                            subTitle: Localization.string("Tap + to create your first alert.")
                        )
                        .padding(16)
                    } else {
                        alertsView(alerts: alerts)
                    }
                } else {
                    tempAlertsView
                }

            }
            .cardBackground()
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 0) {
            Text(Localization.string("Alerts"))
                .font(.satoshiBold(22))
                .foregroundStyle(Color.onSurfaceDim)
                .accessibilityAddTraits(.isHeader)
            
            Spacer(minLength: 16)
            
            Button(action: {
                addNewAlert()
            }, label: {
                Image.add
                    .resizable()
                    .foregroundStyle(Color.onSurfaceDimmer)
                    .frame(width: 24 * min(scale, 1.5), height: 24 * min(scale, 1.5))
                    .padding(12)
            })
            .accessibilityLabel(Localization.format("Add new %@ price alert", cryptoDetailModel?.name ?? ""))
        }
    }

    private var tempAlertsView: some View {
        ForEach(0..<3, id: \.self) { index in
            CryptoDetailAlertCellView(
                name: nil,
                symbol: nil,
                alert: nil,
                index: index,
                alertsCount: 3,
                deleteAlert: { }
            )
            
            if index != 2 {
                Separator()
            }
        }
    }
    
    private func alertsView(alerts: [AlertCoin]) -> some View {
        ForEach(Array(alerts.enumerated()), id: \.element) { index, alert in
            CryptoDetailAlertCellView(
                name: cryptoDetailModel?.name,
                symbol: nil,
                alert: alert,
                index: index,
                alertsCount: alerts.count,
                deleteAlert: {
                    deleteAlert(alert)
                }
            )
            
            if alert != alerts.last {
                Separator()
            }
        }
    }
}
