//
//  DragHandler.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 7/25/25.
//

import SwiftUI

struct DragHandler: View {
    var body: some View {
        Color.outline
            .frame(width: 32, height: 4)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
