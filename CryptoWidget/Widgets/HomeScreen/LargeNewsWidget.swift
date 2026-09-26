//
//  LargeNewsWidget.swift
//  CryptoWidgetExtension
//
//  Created by Oscar Berggren on 2022-02-24.
//

import SwiftUI

struct LargeNewsWidget: View {
    @Environment(\.colorScheme) var scheme

    var entry: NewsEntry
    
    var body: some View {
        GeometryReader { reader in
            
           /* VStack(spacing: 0) {
                
                if let url = URL(string: entry.newsModel.first?.news_url ?? .appName) {
                    
                    Link(destination: url) {
                        
                        ZStack(alignment: .bottomLeading) {
                            
                            if entry.images.first?.cgImage == nil && entry.images.first?.ciImage == nil {
                                
                                Text("?")
                                    .font(.semibold16)
                                    .foregroundColor(Color.onSurfaceDim(for: scheme).opacity(0.7))
                                    .frame(maxWidth: .infinity, maxHeight: reader.size.height / 2, alignment: .center)
                                    .overlay(
                                        ZStack(alignment: .topLeading) {
                                            ScaledBezier(bezierPath:
                                                .priceStillTriangle
                                            )
                                            .fill(Color("shimmeringBackground").opacity(0.15))
                                            .frame(width: 16, height: 12)
                                            .padding(4)
                                            .background(.tertiary.opacity(0.8))
                                            .cornerRadius(4)
                                        }
                                        .frame(maxWidth: reader.size.height, maxHeight: reader.size.height / 2, alignment: .topLeading)
                                        .padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 0))
                                    )
                                
                            } else {
                                
                                Image(uiImage: entry.images.first ?? UIImage())
                                    .resizable()
                                    .widgetAccentedRenderingMode(.desaturated)
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: reader.size.height / 2, alignment: .center)
                                    .overlay(
                                        ZStack(alignment: .topLeading) {
                                            if entry.newsModel.first?.sentiment != nil || entry.newsModel.first == nil {
                                                (entry.newsModel.first?.getSentimentSign ?? .trendStill)
                                                    .foregroundColor(entry.newsModel.first == nil ? Color.shimmeringBackground(for: scheme).opacity(0.15) : entry.newsModel.first?.getSentimentColor(for: scheme) ?? Color.onSurfaceDim(for: scheme))
                                                    .frame(width: 16, height: 12)
                                                    .padding(4)
                                                    .background(.tertiary.opacity(0.8))
                                                    .cornerRadius(4)
                                            }
                                        }
                                        .frame(maxWidth: reader.size.height, maxHeight: reader.size.height / 2, alignment: .topLeading)
                                        .padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 0))
                                    )
                            }
                            
                            LinearGradient(colors: [.black.opacity(0.75), .black.opacity(0.55), .black.opacity(0.4), .clear], startPoint: .bottom, endPoint: .top)
                                .frame(maxWidth: reader.size.width, maxHeight: reader.size.height / 3.3, alignment: .bottom)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                
                                Text(entry.newsModel.first?.title ?? "CoinCurrently")
                                    .foregroundColor(Color.onSurface(for: scheme))
                                    .font(Font.system(size: 14, weight: .semibold))
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                                    .lineSpacing(1.2)

                                Text(entry.newsModel.first?.source_name ?? "Crypto news")
                                    .foregroundColor(Color.onSurface(for: scheme))
                                    .font(Font.system(size: 12, weight: .light))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.top, 4)
                                
                            }
                            .padding(12)
                        }
                        .frame(height: reader.size.height / 2, alignment: .bottomLeading)
                        .clipped()
                        
                    }
                }
                
                Separator()
                
                if let url = URL(string: entry.newsModel[safely: 1]?.news_url ?? .appName) {
                    
                    Link(destination: url) {
                        
                        HStack(spacing: 0) {
                            
                            VStack(alignment: .leading, spacing: 0) {
                                
                                Text(entry.newsModel[safely: 1]?.title ?? "CoinCurrently")
                                    .foregroundColor(Color.onSurface(for: scheme))
                                    .font(Font.system(size: 14, weight: .semibold))
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                                    .lineSpacing(1.2)
                                
                                Spacer(minLength: 4)

                                Text(entry.newsModel[safely: 1]?.source_name ?? "Crypto news")
                                    .foregroundColor(Color.onSurfaceDim(for: scheme))
                                    .font(Font.system(size: 12, weight: .light))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                            }
                            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                
                                if entry.images[safely: 1]?.cgImage == nil && entry.images[safely: 1]?.ciImage == nil {
                                    
                                    Text("?")
                                        .font(.semibold16)
                                        .foregroundColor(Color.onSurfaceDim(for: scheme).opacity(0.7))
                                        .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .center)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.onSurfaceDim(for: scheme).opacity(0.85), lineWidth: 1)
                                                .padding(1)
                                        )
                                        .overlay(
                                            ZStack(alignment: .topTrailing) {
                                                Image.trendStill
                                                    .foregroundStyle(Color.shimmeringBackground(for: scheme).opacity(0.15))
                                                    .frame(width: 16, height: 12)
                                                    .padding(4)
                                                    .background(.tertiary.opacity(0.8))
                                                    .cornerRadius(4)
                                            }
                                            .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .topTrailing)
                                            .padding(8)
                                        )
                                    
                                } else {
                                    
                                    Image(uiImage: entry.images[safely: 1] ?? UIImage())
                                        .resizable()
                                        .widgetAccentedRenderingMode(.desaturated)
                                        .scaledToFill()
                                        .clipped()
                                        .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .center)
                                        .overlay(
                                            ZStack(alignment: .topTrailing) {
                                                if entry.newsModel[safely: 1]?.sentiment != nil || entry.newsModel[safely: 1] == nil {
                                                    (entry.newsModel[safely: 2]?.getSentimentSign ?? .trendStill)
                                                        .foregroundStyle(entry.newsModel[safely: 1] == nil ? Color.shimmeringBackground(for: scheme).opacity(0.15) : entry.newsModel[safely: 1]?.getSentimentColor(for: scheme) ?? Color.onSurfaceDim(for: scheme))
                                                        .frame(width: 16, height: 12)
                                                        .padding(4)
                                                        .background(.tertiary.opacity(0.8))
                                                        .cornerRadius(4)
                                                }
                                            }
                                            .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .topTrailing)
                                            .padding(8)
                                        )
                                }
                            }
                            .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4)
                            .cornerRadius(16)
                            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
                            .clipped()
                            
                        }
                        .frame(maxWidth: reader.size.width, maxHeight: reader.size.height / 4)
                        
                    }
                }
                
                Separator()
                
                if let url = URL(string: entry.newsModel[safely: 2]?.news_url ?? .appName) {
                    
                    Link(destination: url) {
                        
                        HStack(spacing: 0) {
                            
                            VStack(alignment: .leading, spacing: 0) {
                                
                                Text(entry.newsModel[safely: 2]?.title ?? "CoinCurrently")
                                    .foregroundColor(Color.onSurface(for: scheme))
                                    .font(Font.system(size: 14, weight: .semibold))
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                                    .lineSpacing(1.2)
                                
                                Spacer(minLength: 4)
                                
                                Text(entry.newsModel[safely: 2]?.source_name ?? "Crypto news")
                                    .foregroundColor(Color.onSurfaceDim(for: scheme))
                                    .font(Font.system(size: 12, weight: .light))
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                            }
                            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                
                                if entry.images[safely: 2]?.cgImage == nil && entry.images[safely: 2]?.ciImage == nil {
                                    
                                    Text("?")
                                        .font(.semibold16)
                                        .foregroundColor(Color.onSurfaceDim(for: scheme).opacity(0.7))
                                        .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .center)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.onSurfaceDim(for: scheme).opacity(0.85), lineWidth: 1)
                                                .padding(1)
                                        )
                                        .overlay(
                                            ZStack(alignment: .topTrailing) {
                                                ScaledBezier(bezierPath: .priceStillTriangle )
                                                    .fill(Color("shimmeringBackground").opacity(0.15))
                                                    .frame(width: 16, height: 12)
                                                    .padding(4)
                                                    .background(.tertiary.opacity(0.8))
                                                    .cornerRadius(4)
                                            }
                                            .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .topTrailing)
                                            .padding(8)
                                        )
                                    
                                } else {
                                    
                                    Image(uiImage: entry.images[safely: 2] ?? UIImage())
                                        .resizable()
                                        .widgetAccentedRenderingMode(.desaturated)
                                        .scaledToFill()
                                        .clipped()
                                        .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .center)
                                        .overlay(
                                            ZStack(alignment: .topTrailing) {
                                                if entry.newsModel[safely: 2]?.sentiment != nil || entry.newsModel[safely: 2] == nil {
                                                    (entry.newsModel[safely: 2]?.getSentimentSign ?? .trendStill)
                                                        .foregroundColor(entry.newsModel[safely: 2] == nil ? Color.shimmeringBackground(for: scheme).opacity(0.15) : entry.newsModel[safely: 2]?.getSentimentColor(for: scheme) ?? Color.onSurfaceDim(for: scheme))
                                                        .frame(width: 16, height: 12)
                                                        .padding(4)
                                                        .background(.tertiary.opacity(0.8))
                                                        .cornerRadius(4)
                                                }
                                            }
                                            .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4, alignment: .topTrailing)
                                            .padding(8)
                                        )
                                }
                                
                            }
                            .frame(maxWidth: reader.size.height / 4, maxHeight: reader.size.height / 4)
                            .cornerRadius(16)
                            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
                            .clipped()
                            
                        }
                        .frame(maxWidth: reader.size.width, maxHeight: reader.size.height / 4)
                    }
                }
            }*/
        }
    }
}
