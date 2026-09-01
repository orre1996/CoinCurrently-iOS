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

private final class SyncBlockBox<T>: @unchecked Sendable {
    let block: () -> T
    init(_ block: @escaping () -> T) { self.block = block }
    func call() -> T { block() }
}

func asyncMain(delay: Double = 0, _ block: @escaping () -> Void) {
    let box = BlockBox(block)
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        box.call()
    }
}

func syncMain<T>(_ block: @escaping () -> T) -> T {
  if Thread.isMainThread {
    return block()
  } else {
    let box = SyncBlockBox(block)
    return DispatchQueue.main.sync {
      box.call()
    }
  }
}

func onBackgroundThread(block: @escaping () -> Void) {
    let box = BlockBox(block)
    DispatchQueue.global(qos: .background).async {
        box.call()
    }
}
