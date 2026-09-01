//
//  CompareHoverTexts.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-09-28.
//

import SwiftUI

struct CompareHoverTexts: View {
    let hoverTime: String?
    let xPositionTime: CGFloat
    let showMainGraph: Bool
    let mainPrice: String
    let mainColor: Color?
    let xPositionMainPrice: CGFloat
    let mainIndex: Int

    let showCompareGraph: Bool
    let comparePrice: String
    let compareColor: Color?
    let xPositionComparePrice: CGFloat
    let compareIndex: Int

    @Binding var hoverTimeWidthSize: CGFloat
    @Binding var hoverPriceWidthSize: CGFloat
    @Binding var hoverComparePriceWidthSize: CGFloat
    
    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(hoverTime ?? "")
                    .fixedSize(horizontal: false, vertical: true)
                    .readSize {
                        hoverTimeWidthSize = $0.width
                    }
                    .if(!showMainGraph || !showCompareGraph) { view in
                        view.offset(x: xPositionTime)
                    }

                HStack(spacing: 16) {
                    if showMainGraph {
                        HStack(spacing: 8) {
                            if showCompareGraph {
                                (mainColor ?? .onSurfaceDim)
                                    .frame(minWidth: 3, maxWidth: 3, maxHeight: .infinity)
                            }

                            Text(mainIndex < 0 ? "N/A" : mainPrice)
                                .fixedSize(horizontal: false, vertical: true)
                                .readSize {
                                    hoverPriceWidthSize = $0.width
                                }
                                .if(!showCompareGraph) { view in
                                    view.offset(x: xPositionMainPrice)
                                }
                                .layoutPriority(1)
                        }
                        .if(showMainGraph && showCompareGraph) { view in
                            view.frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    
                    if showCompareGraph {
                        HStack(spacing: 8) {
                            Text(compareIndex < 0 ? "N/A" : comparePrice)
                                .fixedSize(horizontal: false, vertical: true)
                                .readSize {
                                    hoverComparePriceWidthSize = $0.width
                                }
                                .if(!showMainGraph) { view in
                                    view.offset(x: xPositionComparePrice)
                                }
                                .layoutPriority(1)
                            
                            if showMainGraph {
                                (compareColor ?? .onSurfaceDim)
                                    .frame(minWidth: 3, maxWidth: 3, maxHeight: .infinity)
                                    .animation(.none, value: UUID())
                            }
                        }
                        .if(showMainGraph && showCompareGraph) { view in
                            view.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .minimumScaleFactor(0.7)
            
            // To always have right height of view
            VStack(spacing: 2) {
                Text("%")
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
                
                Text("%")
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0)
            }
        }
        .animation(.none, value: UUID())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, alignment: showMainGraph && showCompareGraph ? .center : .leading)
        .foregroundColor(.onSurface)
        .font(.poppinsRegular(18))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
    }
}
