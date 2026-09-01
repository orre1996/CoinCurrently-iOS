//
//  UITextViewWrapper.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-05-23.
//

import SwiftUI
import UIKit

struct UITextViewWrapper: UIViewRepresentable {
   typealias UIViewType = UITextView

   @Binding var text: String
   @Binding var calculatedHeight: CGFloat

   func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
       let textField = UITextView()
       textField.delegate = context.coordinator

       textField.isEditable = true
       
       let font = UIFontMetrics.default.scaledFont(for: UIFont(name: "Satoshi-Regular", size: 16) ?? .systemFont(ofSize: 16))

       textField.font = font
       textField.isSelectable = true
       textField.isUserInteractionEnabled = true
       textField.showsVerticalScrollIndicator = false
       textField.tintColor = UIColor(Color.onSurface)
       textField.backgroundColor = UIColor(Color.clear)
       textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
       return textField
   }

   func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
       if uiView.text != self.text {
           uiView.text = self.text
       }

       UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
   }

   fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
       let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
       if result.wrappedValue != newSize.height {
           asyncMain {
               result.wrappedValue = max(88, newSize.height)
           }
       }
   }

   func makeCoordinator() -> Coordinator {
       return Coordinator(text: $text, height: $calculatedHeight)
   }

   final class Coordinator: NSObject, UITextViewDelegate {
       var text: Binding<String>
       var calculatedHeight: Binding<CGFloat>

       init(text: Binding<String>, height: Binding<CGFloat>) {
           self.text = text
           self.calculatedHeight = height
       }

       func textViewDidChange(_ uiView: UITextView) {
           text.wrappedValue = uiView.text
           UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
       }

       func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
           if text == "\n" {
               textView.resignFirstResponder()
               return false
           }
           return true
       }
       
       func textViewDidBeginEditing(_ textView: UITextView) {
           if textView.textColor == UIColor.lightGray {
               textView.text = nil
               textView.textColor = UIColor.black
           }
       }
   }
}
