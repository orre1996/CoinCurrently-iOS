//
//  InputField.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-20.
//

import SwiftUI

enum TextInputButtons {
    case leadingIcon(text: String)
    case trailingIcon(text: String)
    case clearButton
    case magnifyingGlass
}

struct InputField: View {
    @ScaledMetric private var scale: CGFloat = 1

    var placeholder = "Enter value"
    @Binding var input: String
    @Binding var isEditing: Bool
    let accessibilityText: String
    var leadingView: TextInputButtons? = nil
    var trailingView: TextInputButtons? = nil
    var keyboardType = UIKeyboardType.decimalPad
    var shouldFormat = true
    var editingChanged: (Bool) -> Void = { _ in }
    var onValueChanged: () -> Void = { }
    var onCommit: () -> Void = { }
    
    var body: some View {
        HStack(spacing: 2) {
            /*if case .leadingIcon(let text) = leadingView {
                Text(text)
                    .foregroundColor(isEditing || !input.isEmpty ? .onSurface : .onSurfaceDim)
                    .font(.poppinsRegular(16))
                    .padding(.trailing, 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            } else if case .magnifyingGlass = leadingView {
                Image.magnifyingGlass
                    .resizable()
                    .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                    .foregroundColor(isEditing || !input.isEmpty ? .onSurface : .onSurfaceDim)
                    .accessibilityHidden(true)
                    .padding(.trailing, 4)
            }*/

            CustomTextField(placeholder: Text(placeholder).font(.satoshiBold(16)).foregroundColor(Color.onSurfaceDim), 
                            text: $input,
                            editingChanged: { editing in
                isEditing = editing
            
                if keyboardType == .decimalPad && !editing {
                    formatField()
                }

                editingChanged(editing)
            }, commit: {
                isEditing = false
                
                if keyboardType == .decimalPad {
                    formatField()
                }

                onCommit()
            })
            .keyboardType(keyboardType)
            .lineLimit(1)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, alignment: .center)
            .background(Color.clear)
            .foregroundColor(.onSurface)
            .cornerRadius(8)
            .accessibilityElement(children: .ignore)
            .accessibilityHint("Double tap to edit")
            .accessibilityValue(accessibilityText)
            .onChange(of: input) {
                onValueChanged()
            }

            /*if case .trailingIcon(let text) = trailingView {
                Text(text)
                    .foregroundColor(isEditing || !input.isEmpty ? .onSurface : .onSurfaceDim)
                    .font(.poppinsRegular(16))
                    .padding(.leading, 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            } else if case .clearButton = trailingView, isEditing, !input.isEmpty {
                Button(action: {
                    input = ""
                }) {
                    Image.clearButton
                        .resizable()
                        .frame(width: 20 * min(scale, 1.5), height: 20 * min(scale, 1.5))
                        .foregroundColor(Color.onSurface)
                }
            }*/
        }
        .padding(.horizontal, 16)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(1000)
        .modifier(
            BorderModifier(
                color: [Color.outlineVariant],
                cornerRadius: 1000
            )
        )
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, alignment: .center)
        .accessibilityElement(children: .contain)
        .onTapGesture { }
    }
    
    private func formatField() {
        let doubleInput = input.description.trimmedInput().toInputDouble

        guard doubleInput ?? 0 > 0 else {
            input = ""
            return
        }
        
        if shouldFormat {
            input = doubleInput?.removeZerosFromEnd(maximumDigits: 7) ?? ""
        } else {
            input = input.description.trimmedInput()
        }
    }
}

#Preview {
    InputField(input: .constant(""),
               isEditing: .constant(false),
               accessibilityText: "",
               editingChanged: { _ in },
               onCommit: { })
}
