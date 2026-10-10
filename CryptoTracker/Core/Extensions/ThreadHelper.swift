//
//  ThreadHelper.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2022-08-12.
//

import Foundation

private final class BlockBox: @unchecked Sendable {
    let block: () -> Void
    init(_ block: @escaping () -> Void) { self.block = block }
    func call() { block() }
}

func asyncMain(delay: Double = 0, _ block: @escaping () -> Void) {
    let box = BlockBox(block)
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        box.call()
    }
}
