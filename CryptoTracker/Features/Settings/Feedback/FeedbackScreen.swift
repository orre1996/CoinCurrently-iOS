//
//  FeedbackScreen.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-05.
//

import SwiftUI

struct FeedbackScreen: View {
    @ScaledMetric private var scale: CGFloat = 1
    
    @Environment(NavigationViewModel.self) private var navigationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var viewModel = PriceAlertsViewModelImp()
    
    @State private var validInput = false
    @State private var isLoading = false
    @State private var feedback = ""
    @State private var rating: Int? = nil
    @State private var showError = false
    
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Localization.string("How’s your experience with CoinCurrently?"))
                            .font(.satoshiMedium(14))
                            .padding(.horizontal, 16)
                        
                        ratingView
                        
                        inputField
                            .padding(
                                EdgeInsets(
                                    top: 32,
                                    leading: 16,
                                    bottom: 0,
                                    trailing: 16
                                )
                            )
                    }
                    .foregroundStyle(Color.onSurfaceDim)
                    .padding(.vertical, 24)
                }
                
                Separator()
                    .padding(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )

                actionButton
                    .padding(
                        EdgeInsets(
                            top: 0,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitle(Localization.string("Help us Improve"))
    }
    
    private var ratingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1..<6, id: \.self) { index in
                    Button(action: {
                        endTextEditing()
                        
                        withAnimation {
                            rating = index
                        }
                    }, label: {
                        Text("\(index)")
                            .font(.satoshiMedium(16))
                            .foregroundColor(rating == index ? Color.onPrimary : Color.onSurface)
                            .lineLimit(1)
                            .padding(
                                EdgeInsets(
                                    top: 12,
                                    leading: 18,
                                    bottom: 12,
                                    trailing: 18
                                )
                            )
                            .optionalGlassEffect(
                                color: rating == index ? Color.primary : Color.surfaceContainerHigh,
                                radius: 1000,
                                isInteractive: true
                            )
                            .accessibilityLabel(Localization.format("Vote %d of %d.", index, 5))
                            .accessibilityAddTraits(rating == index ? [.isSelected] : [])
                    })
                }
            }
            .optionalGlassEffectContainer(spacing: 8)
            .padding(
                EdgeInsets(
                    top: 8,
                    leading: 16,
                    bottom: 8,
                    trailing: 16
                )
            )
        }
    }
    
    @ViewBuilder
    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.string("How can we improve? (Optional)"))
                .font(.satoshiMedium(14))
                .foregroundStyle(Color.onSurfaceDim)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            
            ZStack {
                HStack(spacing: 0) {
                    Text(Localization.string("Enter your feedback"))
                        .font(.satoshiRegular(16))
                        .foregroundStyle(Color.onSurfaceDimmer)
                        .opacity(feedback.isEmpty ? 1 : 0)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                }
                .padding(.top, 12)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                
                UITextViewWrapper(text: $feedback, calculatedHeight: .constant(132))
                    .padding(.leading, -4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityHint(Localization.string("Double tap to edit"))
                    .accessibilityLabel(Localization.format("%@. Textfield", feedback.isEmpty ? Localization.string("Input feedback here") : Localization.format("feedback: %@", feedback)))
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(Color.clear)
            .foregroundStyle(Color.onSurface)
            .padding(.horizontal, 16)
            .cornerRadius(8)
            .modifier(BorderModifier(color: [feedback.count <= 800 ? Color.outlineVariant : Color.trendDown]))
            
            Text(Localization.format("%d / 800 characters", feedback.count))
                .font(.satoshiMedium(14))
                .foregroundColor(feedback.count <= 200 ? .onSurfaceDimmer : .trendDown)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
        }
    }
    
    private var actionButton: some View {
        PrimaryButton(
            text: Localization.string("Submit Feedback"),
            isEnabled: rating != nil,
            isLoading: isLoading,
            fullWidth: true,
        ) {
            guard let rating else {
                return
            }
            
            isLoading = true
            
            Task {
                let success = await viewModel.sendFeedback(rating: rating , feedback: feedback)
                isLoading = false
                
                if success {
                    presentationMode.wrappedValue.dismiss()
                    showSnackBar(
                        message: Localization.string("Feedback sent, thank you very much!"),
                        type: .success
                    )
                    
                    AnalyticsManager.shared.log(
                        FeedbackSent(fromScreen: .settings, rating:  rating)
                    )
                    
                    if rating >= 4 {
                        NotificationCenter.default.post(Notification(name: .showRatingView, object: nil, userInfo: ["force" : true]))
                    }
                }
            }
        }
        .accessibilityLabel(validInput ? Localization.string("Submit Feedback") : Localization.string("Submit: Disabled because invalid or no rating is entered"))
    }
}
