//
//  PrivacyPolicyView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-08-02.
//

import SwiftUI

struct PrivacyPolicyView: View {
    
    var close: () -> ()
    
    var body: some View {
        
        ZStack {
            
            Color.overlayBackground
                .opacity(0.7)
                .ignoresSafeArea()
                .highPriorityGesture(DragGesture())
                .onTapGesture {
                    close()
                }

            VStack(spacing: 0) {
                Text("Privacy Policy")
                    .foregroundColor(.primaryTextColor)
                    .font(.semibold16)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("We do not collect any personal data. Any collected data is used to improve the app. We do not share the data with anyone.\n\nThe app does use third-party services that may collect information used to identify you.")
                    .foregroundColor(.primaryTextColor)
                    .font(.regular16)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    if let url = URL(string: "https://firebase.google.com/support/privacy/") {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    Text("Firebase Crashlytics")
                        .foregroundColor(.blue)
                })
                .padding(.top, 8)
                
                PrimaryButton(text: "Close") {
                    close()
                }
                .padding(.top, 16)
                
            }
            .padding(16)
            .cornerRadius(8)
            .background(Color.primaryBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(LinearGradient(colors: [Color.mainGray], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    .padding(0.5)
            )
            .multilineTextAlignment(.center)
            .foregroundColor(.primaryTextColor)
            .frame(width: 340, alignment: .center)
            .padding(.horizontal, 16)
        }
    }
}
