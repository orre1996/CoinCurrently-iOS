//
//  SelectExportFormatSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 8/17/26.
//

import SwiftUI

struct SelectExportFormatSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    
    let formatSelected: (PortfolioExportFormat) -> Void
    
    private var sheetHeight: CGFloat {
        guard headerHeight > 0, contentHeight > 0 else {
            return estimatedSheetHeight
        }
        
        return headerHeight + contentHeight + 16 - safeAreaInsets.resolvedBottom
    }
    
    private var estimatedSheetHeight: CGFloat {
        620
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Export Portfolio"))
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
                .padding(.horizontal, 16)
            
            ScrollView(.vertical) {
                bodyView
                    .padding(.horizontal, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var bodyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(Localization.string("General"))
            
            exportOption(
                title: "CSV",
                subtitle: Localization.string("Spreadsheet-friendly format."),
                image: .list,
                format: .csv
            )
            
            exportOption(
                title: "JSON",
                subtitle: Localization.string("Structured data format."),
                image: Image(systemName: "curlybraces"),
                format: .json
            )
            
            exportOption(
                title: Localization.string("Plain Text"),
                subtitle: Localization.string("Human-readable format."),
                image: Image(systemName: "doc.text"),
                format: .plainText
            )
            
            sectionHeader(Localization.string("Tax Software (Pro)"))
                .padding(.top, 12)
            
            exportOption(
                title: "Koinly",
                subtitle: Localization.string("Koinly CSV template."),
                image: Image(systemName: "doc.plaintext"),
                format: .koinly
            )
            
            exportOption(
                title: "CoinTracker",
                subtitle: Localization.string("CoinTracker CSV template."),
                image: Image(systemName: "doc.plaintext"),
                format: .coinTracker
            )
            
            exportOption(
                title: "TokenTax",
                subtitle: Localization.string("TokenTax manual CSV format."),
                image: Image(systemName: "doc.plaintext"),
                format: .tokenTax
            )
            
            exportOption(
                title: "ZenLedger",
                subtitle: Localization.string("ZenLedger custom CSV template."),
                image: Image(systemName: "doc.plaintext"),
                format: .zenLedger
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 24)
        .readSize {
            contentHeight = $0.height
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.satoshiBold(12))
            .foregroundStyle(Color.onSurfaceDimmer)
            .padding(.bottom, 8)
    }
    
    private func exportOption(
        title: String,
        subtitle: String,
        image: Image,
        format: PortfolioExportFormat
    ) -> some View {
        TransactionTypeView(
            title: title,
            subtitle: subtitle,
            image: image,
            isSelected: false,
            viewTapped: {
                formatSelected(format)
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
}
