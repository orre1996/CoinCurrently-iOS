//
//  OverflowLayout.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-02-12.
//

import SwiftUI

struct OverflowLayout: Layout {
    var spacing = CGFloat(10)
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let sizes = measureSizes(subviews: subviews, containerWidth: containerWidth)
        return layout(sizes: sizes, containerWidth: containerWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = measureSizes(subviews: subviews, containerWidth: bounds.width)
        let layoutResult = layout(sizes: sizes, containerWidth: bounds.width)
        for (i, subview) in subviews.enumerated() {
            let offset = layoutResult.offsets[i]
            let lineHeight = layoutResult.lineHeights[i]
            let verticalOffset = (lineHeight - sizes[i].height) / 2
            subview.place(
                at: CGPoint(x: offset.x + bounds.minX, y: offset.y + bounds.minY + verticalOffset),
                proposal: ProposedViewSize(width: sizes[i].width, height: sizes[i].height)
            )
        }
    }
    
    private func measureSizes(subviews: Subviews, containerWidth: CGFloat) -> [CGSize] {
        subviews.map { $0.sizeThatFits(.unspecified) }
    }
    
    func layout(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], lineHeights: [CGFloat], size: CGSize) {
        var result: [(CGPoint, CGFloat)] = []
        var currentPosition: CGPoint = .zero
        var lineHeight: CGFloat = 0
        var lineStartIndex = 0
        var maxX: CGFloat = 0

        for size in sizes {
            if currentPosition.x > 0, currentPosition.x + size.width > containerWidth {
                for i in lineStartIndex..<result.count {
                    result[i].1 = lineHeight
                }
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
                lineStartIndex = result.count
            }

            result.append((currentPosition, 0))
            currentPosition.x += size.width
            maxX = max(maxX, currentPosition.x)
            currentPosition.x += spacing
            lineHeight = max(lineHeight, size.height)
        }
        for i in lineStartIndex..<result.count {
            result[i].1 = lineHeight
        }

        let offsets = result.map(\.0)
        let lineHeights = result.map(\.1)
        return (offsets, lineHeights, CGSize(width: maxX, height: currentPosition.y + lineHeight))
    }
}
