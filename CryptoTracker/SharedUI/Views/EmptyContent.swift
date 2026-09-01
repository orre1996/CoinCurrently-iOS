//
//  EmptyContent.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/14/26.
//

import SwiftUI

struct EmptyContent: View {
    let title: String
    let subTitle: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                Text(title)
                    .foregroundStyle(Color.onSurface)
                    .font(.satoshiBold(18))
                
                Text(subTitle)
                    .foregroundStyle(Color.onSurfaceDim)
                    .font(.satoshiRegular(14))
            }
            .accessibilityElement(children: .combine)
            
            if let buttonTitle {
                SecondaryButton(
                    text: buttonTitle,
                    action: {
                        buttonAction?()
                    }
                )
                .padding(.top, 38)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}
