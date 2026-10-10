//
//  Font+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-05-08.
//

import Foundation
import SwiftUI

extension UIFont {
    static func poppinsRegular(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Regular", size: size) ?? .systemFont(ofSize: size)
    }

    static func poppinsSemibold(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-SemiBold", size: size) ?? .systemFont(ofSize: size)
    }
    
    static func satoshiRegular(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Satoshi-Regular", size: size) ?? .systemFont(ofSize: size)
    }
    
    static func satoshiMedium(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Satoshi-Medium", size: size) ?? .systemFont(ofSize: size)
    }
    
    static func satoshiBold(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Satoshi-Bold", size: size) ?? .systemFont(ofSize: size)
    }
}

extension Font {
    static func satoshiRegular(_ size: CGFloat) -> Font {
        return Font.custom("Satoshi-Regular", size: size)
    }
    
    static func satoshiMedium(_ size: CGFloat) -> Font {
        return Font.custom("Satoshi-Medium", size: size)
    }
    
    static func satoshiBold(_ size: CGFloat) -> Font {
        return Font.custom("Satoshi-Bold", size: size)
    }
    
    static func poppinsRegular(_ size: CGFloat) -> Font {
        return Font.custom("Poppins-Regular", size: size)
    }
    
    static func poppinsSemibold(_ size: CGFloat) -> Font {
        return Font.custom("Poppins-SemiBold", size: size)
    }
    
    static let semibold10 = Font(uiFont: .semibold10)
    static let semibold12 = Font(uiFont: .semibold12)
    static let semibold14 = Font(uiFont: .semibold14)
    static let semibold15 = Font(uiFont: .semibold15)
    static let semibold16 = Font(uiFont: .semibold16)
    static let semibold18 = Font(uiFont: .semibold18)
    static let semibold20 = Font(uiFont: .semibold20)
    static let semibold22 = Font(uiFont: .semibold22)
    static let semibold24 = Font(uiFont: .semibold24)
    static let semibold26 = Font(uiFont: .semibold26)
    static let semibold28 = Font(uiFont: .semibold28)
    static let semibold30 = Font(uiFont: .semibold30)
    static let semibold32 = Font(uiFont: .semibold32)
    static let semibold42 = Font(uiFont: .semibold42)
    
    static let medium10 = Font(uiFont: .medium10)
    static let medium12 = Font(uiFont: .medium12)
    static let medium14 = Font(uiFont: .medium14)
    static let medium16 = Font(uiFont: .medium16)
    static let medium18 = Font(uiFont: .medium18)
    static let medium24 = Font(uiFont: .medium24)
    
    static let regular8 =  Font(uiFont: .regular8)
    static let regular10 = Font(uiFont: .regular10)
    static let regular12 = Font(uiFont: .regular12)
    static let regular14 = Font(uiFont: .regular14)
    static let regular16 = Font(uiFont: .regular16)
    static let regular18 = Font(uiFont: .regular18)
    static let regular20 = Font(uiFont: .regular20)
    static let regular22 = Font(uiFont: .regular22)
    static let regular24 = Font(uiFont: .regular24)
    static let regular26 = Font(uiFont: .regular26)
    static let regular28 = Font(uiFont: .regular28)
    static let regular30 = Font(uiFont: .regular30)
    static let regular32 = Font(uiFont: .regular32)
    static let regular42 = Font(uiFont: .regular42)
    
    static let light12 = Font(uiFont: .light12)
    static let light14 = Font(uiFont: .light14)
    static let light16 = Font(uiFont: .light16)
    static let light18 = Font(uiFont: .light18)
    
    // For widgets because UIFont doesn't work there
    
    static let semiboldWidget10 = Font.custom("Poppins-SemiBold", size: 10)
    static let semiboldWidget12 = Font.custom("Poppins-SemiBold", size: 12)
    static let semiboldWidget14 = Font.custom("Poppins-SemiBold", size: 14)
    static let semiboldWidget16 = Font.custom("Poppins-SemiBold", size: 16)
    static let semiboldWidget18 = Font.custom("Poppins-SemiBold", size: 18)
    static let semiboldWidget20 = Font.custom("Poppins-SemiBold", size: 20)
    static let semiboldWidget22 = Font.custom("Poppins-SemiBold", size: 22)
    static let semiboldWidget24 = Font.custom("Poppins-SemiBold", size: 24)
    static let semiboldWidget26 = Font.custom("Poppins-SemiBold", size: 26)
    static let semiboldWidget28 = Font.custom("Poppins-SemiBold", size: 28)
    static let semiboldWidget30 = Font.custom("Poppins-SemiBold", size: 30)
    static let semiboldWidget32 = Font.custom("Poppins-SemiBold", size: 32)
    static let semiboldWidget42 = Font.custom("Poppins-SemiBold", size: 42)
    
    static let mediumWidget12 = Font.custom("Poppins-Medium", size: 12)
    static let mediumWidget14 = Font.custom("Poppins-Medium", size: 14)
    static let mediumWidget16 = Font.custom("Poppins-Medium", size: 16)
    static let mediumWidget18 = Font.custom("Poppins-Medium", size: 18)
    
    static let regularWidget8 =  Font.custom("Poppins-Regular", size: 8)
    static let regularWidget10 = Font.custom("Poppins-Regular", size: 10)
    static let regularWidget12 = Font.custom("Poppins-Regular", size: 12)
    static let regularWidget14 = Font.custom("Poppins-Regular", size: 14)
    static let regularWidget16 = Font.custom("Poppins-Regular", size: 16)
    static let regularWidget18 = Font.custom("Poppins-Regular", size: 18)
    static let regularWidget20 = Font.custom("Poppins-Regular", size: 20)
    static let regularWidget24 = Font.custom("Poppins-Regular", size: 24)
    static let regularWidget32 = Font.custom("Poppins-Regular", size: 32)
    static let regularWidget42 = Font.custom("Poppins-Regular", size: 42)
    
    static let lightWidget12 = Font.custom("Poppins-Light", size: 12)
    static let lightWidget14 = Font.custom("Poppins-Light", size: 14)
    static let lightWidget16 = Font.custom("Poppins-Light", size: 16)
    static let lightWidget18 = Font.custom("Poppins-Light", size: 18)
    
    init(uiFont: UIFont?) {
        self = Font((uiFont ?? .systemFont(ofSize: 16))  as CTFont)
    }
}

extension UIFont {
    static let semibold10 = UIFont(name: "Poppins-SemiBold", size: 10)
    static let semibold12 = UIFont(name: "Poppins-SemiBold", size: 12)
    static let semibold14 = UIFont(name: "Poppins-SemiBold", size: 14)
    static let semibold15 = UIFont(name: "Poppins-SemiBold", size: 15)
    static let semibold16 = UIFont(name: "Poppins-SemiBold", size: 16)
    static let semibold18 = UIFont(name: "Poppins-SemiBold", size: 18)
    static let semibold20 = UIFont(name: "Poppins-SemiBold", size: 20)
    static let semibold22 = UIFont(name: "Poppins-SemiBold", size: 22)
    static let semibold24 = UIFont(name: "Poppins-SemiBold", size: 24)
    static let semibold26 = UIFont(name: "Poppins-SemiBold", size: 26)
    static let semibold28 = UIFont(name: "Poppins-SemiBold", size: 28)
    static let semibold30 = UIFont(name: "Poppins-SemiBold", size: 30)
    static let semibold32 = UIFont(name: "Poppins-SemiBold", size: 32)
    static let semibold42 = UIFont(name: "Poppins-SemiBold", size: 42)
    
    static let medium10 = UIFont(name: "Poppins-Medium", size: 10)
    static let medium12 = UIFont(name: "Poppins-Medium", size: 12)
    static let medium14 = UIFont(name: "Poppins-Medium", size: 14)
    static let medium16 = UIFont(name: "Poppins-Medium", size: 16)
    static let medium18 = UIFont(name: "Poppins-Medium", size: 18)
    static let medium24 = UIFont(name: "Poppins-Medium", size: 24)
    
    static let regular8 =  UIFont(name: "Poppins-Regular", size: 8)
    static let regular10 = UIFont(name: "Poppins-Regular", size: 10)
    static let regular12 = UIFont(name: "Poppins-Regular", size: 12)
    static let regular14 = UIFont(name: "Poppins-Regular", size: 14)
    static let regular16 = UIFont(name: "Poppins-Regular", size: 16)
    static let regular18 = UIFont(name: "Poppins-Regular", size: 18)
    static let regular20 = UIFont(name: "Poppins-Regular", size: 20)
    static let regular22 = UIFont(name: "Poppins-Regular", size: 22)
    static let regular24 = UIFont(name: "Poppins-Regular", size: 24)
    static let regular26 = UIFont(name: "Poppins-Regular", size: 26)
    static let regular28 = UIFont(name: "Poppins-Regular", size: 28)
    static let regular30 = UIFont(name: "Poppins-Regular", size: 30)
    static let regular32 = UIFont(name: "Poppins-Regular", size: 32)
    static let regular42 = UIFont(name: "Poppins-Regular", size: 42)
    
    static let light12 = UIFont(name: "Poppins-Light", size: 12)
    static let light14 = UIFont(name: "Poppins-Light", size: 14)
    static let light16 = UIFont(name: "Poppins-Light", size: 16)
    static let light18 = UIFont(name: "Poppins-Light", size: 18)
}
