//
//  FirebaseFunctions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-09-25.
//

import Foundation
import FirebaseFunctions
import FirebaseAppCheck

class FirebaseFunctions {
    public static let shared = FirebaseFunctions()
    
    lazy var functions = Functions.functions()
    
    func test() {
        let options = HTTPSCallableOptions(requireLimitedUseAppCheckTokens: true)
        
       // options.
        functions.httpsCallable("helloWorld", options: options).call() { result, error in

            print(result?.data)
            print(error)
            print()
        }
    }
}
