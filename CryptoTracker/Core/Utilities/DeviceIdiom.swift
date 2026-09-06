//
//  UtilityFunctions.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-08-03.
//

import UIKit

#if IS_APP
let isPhone: Bool = MainActor.assumeIsolated { UIDevice.current.userInterfaceIdiom == .phone }
let isPad: Bool = MainActor.assumeIsolated { UIDevice.current.userInterfaceIdiom == .pad }
#endif
