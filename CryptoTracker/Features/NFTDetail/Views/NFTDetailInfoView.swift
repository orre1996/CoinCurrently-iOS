//
//  NFTDetailInfoView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-10-08.
//

import SwiftUI

struct NFTDetailInfoView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    var viewModel: NFTDetailViewModelImp
    
    @Binding var selectedUrl: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let description = viewModel.nftDetailInfo.description, !description.isEmpty {
                    CryptoDetailInfoCell(
                        title: "Description",
                        contents: [description],
                        icons: [],
                        fromScreen: .nftDetail,
                        infoUrl: $selectedUrl
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    emptyView
                }
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16 + safeAreaInsets.resolvedBottom, trailing: 16))
        }
        .refreshable {
            await viewModel.refresh()
        }
        .padding(EdgeInsets(top: 0, leading: safeAreaInsets.leading, bottom: 0, trailing: safeAreaInsets.trailing))
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        Text("Information missing")
            .foregroundColor(.onSurface)
            .font(.poppinsRegular(16))
            .frame(maxWidth: .infinity)
            .modifier(CardBackground())
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
