//
//  Test.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-01-07.
//

import Foundation
import SwiftUI

final class KeyboardResponder: ObservableObject {
    
    private var notificationCenter: NotificationCenter
    @Published private(set) var currentHeight: CGFloat = 0
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @MainActor
    func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }
    
    @objc func keyBoardWillHide(notification: Notification) {
        asyncMain { [weak self] in
            self?.currentHeight = 0
        }
    }
}

struct KeyboardView<Content> : View where Content : View {
    @StateObject private var keyboard: KeyboardResponder = KeyboardResponder()
    var content: () -> Content
    var hideToolbar: Bool = false
    
    var body: some View {
        ZStack {
            content()
            
            VStack {
                Spacer()
                
                HStack {
                    
                    Spacer()
                    
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }, label: {
                        Text("Close")
                            .foregroundColor(.blue)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Close keyboard")
                    })
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color("keyboardCover"))
                .padding(.bottom, keyboard.currentHeight)
                .animation(.interpolatingSpring(mass: 1, stiffness: 120, damping: 20, initialVelocity: 0.95), value: keyboard.currentHeight)
            }
            .accentColor(.blue)
            .opacity((keyboard.currentHeight == 0 || hideToolbar) ? 0 : 1)
        }
    }
}


