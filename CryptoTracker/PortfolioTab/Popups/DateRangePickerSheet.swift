//
//  DateFilterSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 1/16/26.
//

import SwiftUI

enum DateRangePickerMode: String, Identifiable {
    case date
    case time
    
    var id: String { rawValue }
    
    var dateComponents: DatePickerComponents {
        switch self {
        case .date: .date
        case .time: .hourAndMinute
        }
    }
}

struct DateRangePickerSheet: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.sizeCategory) private var category
    
    @State private var selectedDate: Date
    @State private var dateRange: ClosedRange<Date>
    
    @State private var headerHeight: CGFloat = 0
    @State private var buttonsHeight: CGFloat = 0
    
    let fromScreen: ScreenLabel
    let dateComponents: DatePickerComponents
    
    let applyDate: (Date) -> Void
    
    init(
        fromScreen: ScreenLabel,
        dateComponents: DatePickerComponents,
        initialDate: Date = Date(),
        dateRange: ClosedRange<Date>? = nil,
        applyDate: @escaping (Date) -> Void
    ) {
        self.fromScreen = fromScreen
        self.dateComponents = dateComponents
        self.applyDate = applyDate
        
        if dateComponents == .hourAndMinute {
            _selectedDate = State(initialValue: initialDate)
            _dateRange = State(initialValue: initialDate...initialDate)
        } else {
            let resolvedRange = dateRange ?? (
                (Date().setTime(year: 2009, month: 01, day: 01) ?? Date())...Date()
            )
            let clampedDate = min(max(initialDate, resolvedRange.lowerBound), resolvedRange.upperBound)
            
            _selectedDate = State(initialValue: clampedDate)
            _dateRange = State(initialValue: resolvedRange)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DragHandle(title: "Select \(dateComponents == .date ? "Date" : "Time")")
                .readSize {
                    headerHeight = $0.height
                }
            
            Separator()
            
            datePicker
                .labelsHidden()
                .accessibilityLabel(dateComponents == .date ? "Select date" : "Select time")
                .datePickerStyle(.wheel)
                .colorScheme(.light)
                .environment(\.locale, Date.uses24HourClock ? Locale(identifier: "en_GB") : Locale(identifier: "en_US"))
                .colorInvert()
                .colorMultiply(Color.onSurface)
                .frame(height: 200)
                .clipped()
            
            Separator()
                .padding(.horizontal, 16)
            
            actionButtons
                .readSize {
                    buttonsHeight = $0.height
                }
        }
        .presentationDetents([.height(max(1, headerHeight + 200 + buttonsHeight + 24 - safeAreaInsets.resolvedBottom))])
        .presentationBackground(Color.surfaceContainerLow)
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    private var datePicker: some View {
        if dateComponents == .hourAndMinute {
            DatePicker(
                selection: $selectedDate,
                displayedComponents: dateComponents,
                label: {
                    Text("")
                }
            )
        } else {
            DatePicker(
                selection: $selectedDate,
                in: dateRange,
                displayedComponents: dateComponents,
                label: {
                    Text("")
                }
            )
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isHorizontal = !category.isAccessibilityCategory || verticalSizeClass == .compact

        AdaptiveStack(isHorizontal: isHorizontal, spacing: 8) {
            SecondaryButton(
                text: "Cancel",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    presentationMode.wrappedValue.dismiss()
                }
            )

            PrimaryButton(
                text: "Apply",
                accessibilityLabel: "Apply filters",
                fullWidth: true,
                opaqueBackground: true,
                action: {
                    AnalyticsManager.shared.log(
                        DatePickerValueConfirmed(
                            fromScreen: fromScreen,
                            pickerKind: dateComponents == .date ? "date" : "time"
                        )
                    )
                    applyDate(selectedDate)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .padding(
            EdgeInsets(
                top: 24,
                leading: 16,
                bottom: 16,
                trailing: 16
            )
        )
    }
}
