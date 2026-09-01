//
//  PriceVolumeModel.swift
//  CryptoTracker
//
//  Created by Oscar Berggren on 2020-10-27.
//

import Foundation
import SwiftUI

struct PriceVolumeModel: Codable, Hashable {
    var prices: [[Double?]]? = nil
    var market_caps: [[Double?]]? = nil
    var total_volumes: [[Double?]]? = nil
}
