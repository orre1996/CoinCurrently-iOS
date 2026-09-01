//
//  SectionHeader.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-17.
//

import SwiftUI

struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.satoshiBold(22))
            .foregroundStyle(Color.onSurfaceDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}
