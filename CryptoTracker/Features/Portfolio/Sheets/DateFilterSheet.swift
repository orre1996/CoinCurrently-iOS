//
//  DateFilterSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/16/26.
//

import SwiftUI

enum DateFieldOption {
    case start
    case end
}

struct DateFilterSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    @State var startDate: Date? = nil
    @State var endDate: Date? = nil

    let fromScreen: ScreenLabel
    let selectDate: (DateFieldOption) -> Void
    let clearDate: () -> Void
    let applyDate: (DateOption) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: Localization.string("Filter By Date"))
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    startDateField
                        .padding(.bottom, 24)
                    
                    endDateField
                }
                .padding(
                    EdgeInsets(
                        top: 24,
                        leading: 16,
                        bottom: 24,
                        trailing: 16
                    )
                )
                .readSize {
                    contentHeight = $0.height
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            
            Separator()
                .padding(.horizontal, 16)
            
            actionButtons
                .readSize {
                    buttonsHeight = $0.height
                }
        }
        .presentationDetents([.height(max(1, headerHeight + contentHeight + buttonsHeight - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var startDateField: some View {
        let formattedStartDate = startDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
        let accessibleStartDate = startDate?.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) ?? Localization.string("Enter start date")
        
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.string("Start Date"))
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            TextInputField(
                input: .constant(formattedStartDate),
                placeholder: "Start Date",
                accessibilityValue: formattedStartDate.isEmpty ? Localization.string("Enter start date") : formattedStartDate,
                leadingIcon: .date,
                inputDidChange: { },
                onCommit: { }
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.format("Start Date: %@", accessibleStartDate))
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            AnalyticsManager.shared.log(
                DateFilterCustomFieldOpened(fromScreen: fromScreen, field: .start)
            )
            presentationMode.wrappedValue.dismiss()
            selectDate(.start)
        }
    }
    
    @ViewBuilder
    private var endDateField: some View {
        let formattedEndDate = endDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
        let accessibleEndDate = endDate?.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) ?? Localization.string("Enter end date")
        
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.string("End Date"))
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            TextInputField(
                input: .constant(formattedEndDate),
                placeholder: "End Date",
                accessibilityValue: formattedEndDate.isEmpty ? Localization.string("Enter end date") : formattedEndDate,
                leadingIcon: .date,
                inputDidChange: { },
                onCommit: { }
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.format("End Date: %@", accessibleEndDate))
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            AnalyticsManager.shared.log(
                DateFilterCustomFieldOpened(fromScreen: fromScreen, field: .end)
            )
            presentationMode.wrappedValue.dismiss()
            selectDate(.end)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 8) {
            SecondaryButton(
                text: Localization.string("Clear"),
                accessibilityLabel: Localization.string("Clear filters"),
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    AnalyticsManager.shared.log(
                        DateFilterCustomCleared(fromScreen: fromScreen)
                    )
                    startDate = nil
                    endDate = nil
                    clearDate()
                }
            )

            PrimaryButton(
                text: Localization.string("Apply"),
                isEnabled: startDate != nil && endDate != nil,
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    guard let startDate, let endDate else {
                        return
                    }
                    
                    AnalyticsManager.shared.log(
                        DateFilterCustomApplied(fromScreen: fromScreen)
                    )
                    applyDate(DateOption.custom(startDate: startDate, endDate: endDate))
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 24,
                trailing: 16
            )
        )
    }
}
