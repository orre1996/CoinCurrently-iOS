//
//  FearGreedPaths.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-10.
//

import SwiftUI

#if IS_APP
func getIndexColor(indexValue: String) -> Color {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 20) { return .extremeFear }
    else if (intValue < 40)  { return .fear }
    else if (intValue < 60)  { return .neutral }
    else if (intValue < 80)  { return .greed }
    else { return .extremeGreed }
}
#elseif IS_WIDGET || IS_WATCH
func getIndexColor(
    indexValue: String,
    for scheme: ColorScheme
) -> Color {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 20) { return .extremeFear(for: scheme) }
    else if (intValue < 40)  { return .fear(for: scheme) }
    else if (intValue < 60)  { return .neutral(for: scheme) }
    else if (intValue < 80)  { return .greed(for: scheme) }
    else { return .extremeGreed(for: scheme) }
}
#endif

func getIndexString(indexValue: String) -> String {
    let intValue = Int(indexValue) ?? 0

    if (intValue < 20) { return "Extreme Fear" }
    else if (intValue < 40)  { return "Fear" }
    else if (intValue < 60)  { return "Neutral" }
    else if (intValue < 80)  { return "Greed" }
    else { return "Extreme Greed" }
}
