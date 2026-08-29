//
//  DragDropHelper.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-06-18.
//

import SwiftUI
import UIKit

struct DragDropHelper: DropDelegate {
    let item: Toplist

    @Binding var items: [Toplist]
    @Binding var draggedItem: Toplist?

    var orderChanged: ([Toplist]) -> Void

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else {
            return
        }

        if draggedItem != item {
            let from = items.firstIndex(of: draggedItem) ?? 0
            let to = items.firstIndex(of: item) ?? 0
            let coinName = item.name ?? item.symbol?.uppercased() ?? "coin"
            let announcement = from > to ? "Before \(coinName)" : "After \(coinName)"
            
            withAnimation(.default) {
                self.items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                orderChanged(items)
            }
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
       return DropProposal(operation: .move)
    }
}
