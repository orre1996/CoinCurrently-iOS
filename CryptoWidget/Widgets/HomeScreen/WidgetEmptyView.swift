//
//  WidgetEmptyView.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 6/18/26.
//

import SwiftUI

struct WidgetEmptyView: View {
    @Environment(\.colorScheme) var scheme
    
    var plural: Bool = true
    
    var body: some View {
        Text(plural
            ? AppCopy.string("Long press and \"Edit Widget\" to\nselect coins to display here.")
            : AppCopy.string("Long press and \"Edit Widget\" to\nselect a coin to display here."))
        .font(.satoshiRegular(16))
        .foregroundStyle(Color.onSurface(for: scheme))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
    }

    static func nextPromptIndex(
        selectedIDs: [String],
        data: [Toplist]? = nil,
        slotCount: Int
    ) -> Int? {
        let lastFilled = (0..<slotCount).last { index in
            let id = selectedIDs[safely: index] ?? data?[safely: index]?.id
            return !(id ?? "").isEmpty
        }
        guard let lastFilled else { return nil }
        let next = lastFilled + 1
        return next < slotCount ? next : nil
    }
}
