//
//  DatePickerSheet.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-01-24.
//

import SwiftUI

struct DatePickerSheet: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.sizeCategory) private var category
    
    @State var date: Date = Date()
    
    let dateRange: ClosedRange<Date>
    let dateComponents: DatePickerComponents
    let setDate: (Date?) -> Void
    let dismiss: () -> Void
    
    @State private var showBackground = false
    @State private var pickerId = UUID()
    
    @AccessibilityFocusState private var focusHeader

    // MARK: - Body
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(showBackground ? 0.7 : 0)
                    .animation(Animation.easeInOut(duration: 0.5), value: showBackground)
                    .onTapGesture {
                        dismissView(date: nil)
                    }
                
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text(dateComponents == .hourAndMinute ? "Pick a time" : "Pick a date")
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.poppinsSemibold(16))
                            .padding(16)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($focusHeader)
                        
                        Separator()
                            .padding(.bottom, 8)
                        
                        DatePicker(
                            selection: $date,
                            in: dateRange,
                            displayedComponents: dateComponents,
                            label: {
                                Text("")
                            }
                        )
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .environment(\.locale, Date.uses24HourClock ? Locale(identifier: "en_GB") : Locale(identifier: "en_US"))
                        .colorInvert()
                        .colorMultiply(Color.onSurface)
                        .frame(height: min(216, reader.size.height - 226))
                        .clipped()
                    }
                    .padding(.bottom, 8)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    
                    AdaptiveStack(
                        isHorizontal: !category.isAccessibilityCategory || verticalSizeClass == .compact,
                        spacing: 16
                    ) {
                        PrimaryButton(text: "Cancel", opaqueBackground: true) {
                            dismissView(date: nil)
                        }
                        .accessibilityLabel("Cancel, close window")
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(8)
                        
                        PrimaryButton(text: "Save", opaqueBackground: true) {
                            dismissView(date: date)
                        }
                        .accessibilityLabel("Save, close window")
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                }
                .id(pickerId)
                .font(.poppinsRegular(16))
                .foregroundColor(.onSurface)
                .offset(y: showBackground ? 0 : UIScreen.main.bounds.height)
                .animation(Animation.easeInOut(duration: 0.5), value: showBackground)
                .padding(.bottom, 16 + safeAreaInsets.resolvedBottom)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            showBackground = true
        }
        .onUIKitDidAppear {
            focusHeader = true
        }
    }

    func dismissView(date: Date?) {
        showBackground = false

        setDate(date)

        asyncMain(delay: 0.5) {
            dismiss()
        }
    }
}
