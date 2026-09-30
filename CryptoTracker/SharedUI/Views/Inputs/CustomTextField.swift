//
//  CustomTextField.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-02-05.
//

import SwiftUI

struct CustomTextField: View {
    var placeholder: Text
    var isEditing: Bool = false
    @Binding var text: String
    var editingChanged: (Bool) -> () = { _ in }
    var commit: () -> () = { }
    var smallerText: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
                    .padding(.trailing, isEditing ? 40 : 2)
                    .minimumScaleFactor(isEditing || smallerText ? 0.5 : 0.9)
                    .accessibilityHidden(true)
            }
            
            TextField("", text: $text, onEditingChanged: { editing in
                editingChanged(editing)
            }, onCommit: {
                commit()
            })
            .foregroundStyle(Color.onSurface)
            .accessibilityElement(children: .ignore)
            .multilineTextAlignment(.leading)
            .font(.satoshiBold(16))
            .accessibilityHint(AppCopy.string("Double tap to edit"))
            .accessibilityValue(
                text.isEmpty
                    ? AppCopy.string("Textfield")
                    : AppCopy.format("%@. Textfield", text)
            )
#if !os(watchOS)
            .disableAutocorrection(true)
#endif
        }
        .animation(.none, value: text)
    }
}
