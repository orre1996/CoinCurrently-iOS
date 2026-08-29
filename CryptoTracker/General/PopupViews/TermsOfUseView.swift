//
//  TermsOfUseView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-08-02.
//

import SwiftUI

struct TermsOfUseView: View {
    
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
                Text("Terms of Service")
                    .foregroundColor(.primaryTextColor)
                    .font(.semibold16)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Price data is gathered from CoinGecko. We do not take resposibility for the accuracy or stability of their API. Always check prices directly on exchanges before making a financial decision.\n\nPrice notifications require stable internet connection. Make sure to check prices manually in regular intervals in case of notification delivery failure.")
                    .foregroundColor(.primaryTextColor)
                    .font(.regular16)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
