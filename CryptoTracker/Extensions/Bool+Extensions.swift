//
//  Bool+Extensions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2021-05-29.
//

import Foundation
import UIKit

extension UIDevice {
    static var hasHomeButton: Bool {
        let window = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        guard let safeAreaBottom =  window?.safeAreaInsets.bottom else {
            return false
        }

        return safeAreaBottom <= 0
    }
    
    func getSafeAreaTop() -> CGFloat {
        
        let keyWindow = UIApplication.shared.connectedScenes
        
            .filter({$0.activationState == .foregroundActive})
        
            .map({$0 as? UIWindowScene})
        
            .compactMap({$0})
        
            .first?.windows
        
            .filter({$0.isKeyWindow}).first
        
        return (keyWindow?.safeAreaInsets.top) ?? 0
        
    }

    func getSafeAreaBottom() -> CGFloat {
        
        let keyWindow = UIApplication.shared.connectedScenes
        
            .filter({$0.activationState == .foregroundActive})
        
            .map({$0 as? UIWindowScene})
        
            .compactMap({$0})
        
            .first?.windows
        
            .filter({ $0.isKeyWindow }).first
        
        return (keyWindow?.safeAreaInsets.bottom) ?? 0
        
    }
    
    func getSafeAreaLeading() -> CGFloat {
        
        let keyWindow = UIApplication.shared.connectedScenes
        
            .filter({$0.activationState == .foregroundActive})
        
            .map({$0 as? UIWindowScene})
        
            .compactMap({$0})
        
            .first?.windows
        
            .filter({$0.isKeyWindow}).first
        
        return (keyWindow?.safeAreaInsets.left) ?? 0
        
    }

    func getSafeAreaTrailing() -> CGFloat {
        
        let keyWindow = UIApplication.shared.connectedScenes
        
            .filter({$0.activationState == .foregroundActive})
        
            .map({$0 as? UIWindowScene})
        
            .compactMap({$0})
        
            .first?.windows
        
            .filter({ $0.isKeyWindow }).first
        
        return (keyWindow?.safeAreaInsets.right) ?? 0
        
    }
}

extension Bool {
    var intValue: Int {
        self == true ? 1 : 0
    }
}
