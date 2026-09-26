//
//  HeatmapGridView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2026-08-18.
//

import SwiftUI

struct HeatmapTile: Identifiable {
    let coin: Toplist
    let frame: CGRect
    
    var id: String {
        coin.id ?? coin.symbol ?? coin.name ?? ""
    }
}

struct HeatmapGridView: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @ScaledMetric private var minCellSide: CGFloat = 52
    
    let coins: [Toplist]
    let selectedTimeframe: PriceChange
    let weighting: HeatmapWeighting
    let coinSelected: (Toplist) -> Void
    
    var body: some View {
        let _ = Self._printChanges()
        
        GeometryReader { reader in
            let topInset = safeAreaInsets.top + 48
            let bottomInset = safeAreaInsets.bottom + 48
            
            Group {
                if weighting == .equal {
                    let layoutViewport = CGSize(
                        width: max(1, reader.size.width),
                        height: max(1, reader.size.height - topInset - bottomInset)
                    )
                    let layout = HeatmapLayout.layout(
                        coins: coins,
                        viewport: layoutViewport,
                        spacing: 0,
                        weighting: weighting,
                        minCellSide: minCellSide
                    )
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        heatmapTiles(layout: layout)
                            .padding(.top, topInset)
                            .padding(.bottom, bottomInset)
                    }
                    .frame(width: reader.size.width, height: reader.size.height)
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    let layoutViewport = CGSize(
                        width: max(1, reader.size.width),
                        height: max(1, reader.size.height - topInset - bottomInset)
                    )
                    let layout = HeatmapLayout.layout(
                        coins: coins,
                        viewport: layoutViewport,
                        spacing: 0,
                        weighting: weighting,
                        minCellSide: minCellSide
                    )
                    
                    ZoomableHeatmapScrollView(
                        contentSize: layout.size,
                        contentInsets: UIEdgeInsets(
                            top: topInset,
                            left: 0,
                            bottom: bottomInset,
                            right: 0
                        ),
                        // Fit the packed treemap into the visible area; pinch to zoom in.
                        minZoomScale: min(
                            1,
                            layoutViewport.width / max(layout.size.width, 1),
                            layoutViewport.height / max(layout.size.height, 1)
                        )
                    ) {
                        heatmapTiles(layout: layout)
                    }
                    .frame(width: reader.size.width, height: reader.size.height)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: weighting)
            .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)
        }
    }
    
    @ViewBuilder
    private func heatmapTiles(layout: HeatmapLayout.Pack) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.tiles) { tile in
                HeatmapCellView(
                    coin: tile.coin,
                    selectedTimeframe: selectedTimeframe,
                    action: {
                        coinSelected(tile.coin)
                    }
                )
                .frame(width: tile.frame.width, height: tile.frame.height)
                .clipped()
                .position(x: tile.frame.midX, y: tile.frame.midY)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
    }
}

private struct ZoomableHeatmapScrollView<Content: View>: UIViewRepresentable {
    let contentSize: CGSize
    let contentInsets: UIEdgeInsets
    let minZoomScale: CGFloat
    @ViewBuilder let content: () -> Content
    
    private let maxZoomScale: CGFloat = 3.0
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> HeatmapZoomScrollView {
        let scrollView = HeatmapZoomScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoomScale
        scrollView.maximumZoomScale = max(maxZoomScale, minZoomScale)
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        // Allow pinch/pan to take over even when fingers start on different coin buttons.
        scrollView.canCancelContentTouches = true
        scrollView.delaysContentTouches = false
        
        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = CGRect(origin: .zero, size: contentSize)
        scrollView.addSubview(hostingController.view)
        scrollView.contentSize = contentSize
        scrollView.contentInset = contentInsets
        scrollView.zoomScale = minZoomScale
        scrollView.contentOffset = CGPoint(x: -contentInsets.left, y: -contentInsets.top)
        
        context.coordinator.hostingController = hostingController
        context.coordinator.scrollView = scrollView
        context.coordinator.lastContentSize = contentSize
        context.coordinator.lastContentInsets = contentInsets
        return scrollView
    }
    
    func updateUIView(_ scrollView: HeatmapZoomScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content()
        context.coordinator.hostingController?.view.frame = CGRect(origin: .zero, size: contentSize)
        scrollView.contentSize = contentSize
        scrollView.contentInset = contentInsets
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.minimumZoomScale = minZoomScale
        scrollView.maximumZoomScale = max(maxZoomScale, minZoomScale)
        
        let sizeChanged = context.coordinator.lastContentSize != contentSize
        let insetsChanged = context.coordinator.lastContentInsets != contentInsets
        if sizeChanged || insetsChanged {
            scrollView.zoomScale = minZoomScale
            scrollView.contentOffset = CGPoint(x: -contentInsets.left, y: -contentInsets.top)
            context.coordinator.lastContentSize = contentSize
            context.coordinator.lastContentInsets = contentInsets
        }
    }
    
    final class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        weak var scrollView: HeatmapZoomScrollView?
        var lastContentSize: CGSize = .zero
        var lastContentInsets: UIEdgeInsets = .zero
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }
    }
}

/// Cancels touches on coin buttons so a two-finger pinch can begin across tiles.
private final class HeatmapZoomScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}

private struct HeatmapCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var scale: CGFloat = 1
    
    let coin: Toplist
    let selectedTimeframe: PriceChange
    let action: () -> Void
    
    var body: some View {
        let _ = Self._printChanges()
        let change = coin.getPriceChange(selectedChangeOption: selectedTimeframe)
        
        GeometryReader { reader in
            let width = reader.size.width
            let height = reader.size.height
            let minSide = min(width, height)
            let iconSize = self.iconSize(for: minSide)
            let contentSpacing = min(8, max(2, minSide * 0.025))
            let rowSpacing = min(8, max(4, minSide * 0.03))
            
            VStack(spacing: contentSpacing) {
                HStack(spacing: rowSpacing) {
                    ShimmeringImage(
                        imageUrl: coin.image,
                        downloading: false,
                        size: iconSize,
                        radius: iconSize / 2,
                        showShimmer: false
                    )
                    .fixedSize()
                    .accessibilityHidden(true)
                    
                    Text((coin.symbol ?? "").uppercased())
                        .font(.satoshiBold(symbolFontSize(for: minSide)))
                        .foregroundStyle(Color.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                if showsPrice(for: minSide) {
                    Text(coin.current_price?.formatCurrency(threshold: FormattingThreshold.none) ?? "")
                        .font(.satoshiBold(priceFontSize(for: minSide)))
                        .foregroundStyle(Color.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                
                Text(percentText(for: change))
                    .font(.satoshiBold(percentFontSize(for: minSide)))
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .multilineTextAlignment(.center)
            .padding(cellPadding(for: minSide))
            .frame(width: width, height: height, alignment: .center)
        }
        .background(heatmapColor(for: change))
        .overlay {
            Rectangle()
                .strokeBorder(Color.surface, lineWidth: 1)
        }
        .contentShape(Rectangle())
        // Tap instead of Button so a two-finger pinch across tiles isn't stolen.
        .onTapGesture(perform: action)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabel(change: change))
        .accessibilityHint("Double tap for \(coin.name ?? "") details")
        .accessibilityAction(.default, action)
    }
    
    private func percentText(for change: Double) -> String {
        let sign = change > 0 ? "+" : change < 0 ? "-" : ""
        return "\(sign)\(change.formattedChangePercent())"
    }
    
    private func heatmapColor(for change: Double) -> Color {
        let magnitude = min(abs(change) / 10.0, 1.0)
        if abs(change) < 0.05 {
            return Color.surfaceContainerHigh
        }
        
        let base = change > 0 ? Color.trendUp : Color.trendDown
        let opacity = colorScheme == .dark
            ? 0.32 + magnitude * 0.58
            : 0.18 + magnitude * 0.32
        return base.opacity(opacity)
    }
    
    private func iconSize(for minSide: CGFloat) -> CGFloat {
        min(40 * min(scale, 1.5), max(12, minSide * 0.16))
    }
    
    private func symbolFontSize(for minSide: CGFloat) -> CGFloat {
        min(24, max(10, minSide * 0.11))
    }
    
    private func priceFontSize(for minSide: CGFloat) -> CGFloat {
        min(22, max(9, minSide * 0.09))
    }
    
    private func percentFontSize(for minSide: CGFloat) -> CGFloat {
        min(28, max(10, minSide * 0.1))
    }
    
    private func showsPrice(for minSide: CGFloat) -> Bool {
        minSide >= 52
    }
    
    private func cellPadding(for minSide: CGFloat) -> EdgeInsets {
        let inset = min(16, max(4, minSide * 0.06))
        return EdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
    }
    
    private func accessibilityLabel(change: Double) -> String {
        let price = coin.current_price?.currencyAccessible() ?? ""
        let decimals = change.changePercentDecimalPoints
        let accessibleChange = change.numberAccessible(maxPlaces: decimals)
        return [
            coin.name ?? coin.symbol ?? "",
            "Price: \(price)",
            "\(selectedTimeframe.accessibilityTimeframe) price change: \(change.directionAccessible) \(accessibleChange) percent"
        ].joined(separator: ". ")
    }
}

enum HeatmapLayout {
    struct Pack {
        let tiles: [HeatmapTile]
        let size: CGSize
    }
    
    static func layout(
        coins: [Toplist],
        viewport: CGSize,
        spacing: CGFloat,
        weighting: HeatmapWeighting,
        minCellSide: CGFloat
    ) -> Pack {
        switch weighting {
        case .marketCap:
            return marketCapRows(
                coins: coins,
                viewport: viewport,
                spacing: spacing,
                minCellSide: minCellSide
            )
        case .equal:
            let size = equalContentSize(coinCount: coins.count, viewport: viewport, minCellSide: minCellSide)
            let frames = equalGrid(count: coins.count, in: size, minCellSide: minCellSide)
            return Pack(
                tiles: tiles(from: coins, frames: frames, spacing: spacing),
                size: size
            )
        }
    }
    
    private static func tiles(
        from coins: [Toplist],
        frames: [CGRect],
        spacing: CGFloat
    ) -> [HeatmapTile] {
        zip(coins, frames).compactMap { coin, frame in
            let inset = frame.insetBy(dx: spacing / 2, dy: spacing / 2)
            guard inset.width > 1, inset.height > 1 else { return nil }
            return HeatmapTile(coin: coin, frame: inset)
        }
    }
    
    private static func equalContentSize(coinCount: Int, viewport: CGSize, minCellSide: CGFloat) -> CGSize {
        let width = max(viewport.width, 1)
        let columns = equalColumnCount(for: width, minCellSide: minCellSide)
        let unit = width / CGFloat(columns)
        let rows = max(1, Int(ceil(Double(max(coinCount, 1)) / Double(columns))))
        return CGSize(width: width, height: max(viewport.height, CGFloat(rows) * unit))
    }
    
    private static func equalColumnCount(for width: CGFloat, minCellSide: CGFloat) -> Int {
        let maxColumns: Int
        if width >= 700 {
            maxColumns = 6
        } else if width >= 500 {
            maxColumns = 5
        } else {
            maxColumns = 3
        }
        
        return max(1, min(maxColumns, Int(width / max(minCellSide, 1))))
    }
    
    private static func equalGrid(count: Int, in size: CGSize, minCellSide: CGFloat) -> [CGRect] {
        let cols = equalColumnCount(for: size.width, minCellSide: minCellSide)
        let unit = size.width / CGFloat(cols)
        
        return (0..<count).map { index in
            let column = index % cols
            let row = index / cols
            return CGRect(
                x: CGFloat(column) * unit,
                y: CGFloat(row) * unit,
                width: unit,
                height: unit
            )
        }
    }
    
    private static func marketCapRows(
        coins: [Toplist],
        viewport: CGSize,
        spacing: CGFloat,
        minCellSide: CGFloat
    ) -> Pack {
        let viewportWidth = max(viewport.width, 1)
        let viewportHeight = max(viewport.height, 1)
        
        guard !coins.isEmpty else {
            return Pack(tiles: [], size: CGSize(width: viewportWidth, height: viewportHeight))
        }
        
        let minSpan = 2
        // Short lists (favorites / portfolio) need a tighter range so large caps
        // don't crush the rest. Toplist keeps the full span range.
        let isShortList = coins.count <= 20
        let maxSpan = isShortList ? marketCapMaxSpan(coinCount: coins.count) : 12
        let spans = marketCapSpans(coins: coins, minSpan: minSpan, maxSpan: maxSpan)
        var areas = spans.map { Double($0 * $0) }
        
        if isShortList {
            let minShare = Double(minCellSide) / Double(viewportWidth)
            areas = enforceMinimumAreaShare(areas: areas, minShare: minShare)
        }
        
        // Fill a square canvas completely (no empty pack holes). Unit sizing keeps
        // the smallest tiles near `minCellSide`; the scroll view zooms to fit.
        let sideInCells = sqrt(areas.reduce(0, +))
        let baseUnit = max(minCellSide / CGFloat(minSpan), viewportWidth / CGFloat(maxSpan + 4))
        let unit = max(baseUnit, viewportWidth / CGFloat(sideInCells))
        let side = CGFloat(sideInCells) * unit
        
        return Pack(
            tiles: tiles(from: coins, frames: rowFrames(areas: areas, side: side), spacing: spacing),
            size: CGSize(width: side, height: side)
        )
    }
    
    /// Caps how extreme market-cap sizing can get for short lists (favorites / portfolio).
    private static func marketCapMaxSpan(coinCount: Int) -> Int {
        switch coinCount {
        case ...2:
            return 4
        case ...4:
            return 5
        case ...8:
            return 7
        default:
            return 9
        }
    }
    
    /// Lifts undersized tiles toward `minShare` of total area by taking from larger ones.
    private static func enforceMinimumAreaShare(areas: [Double], minShare: Double) -> [Double] {
        guard areas.count > 1 else { return areas }
        
        let total = areas.reduce(0, +)
        guard total > 0 else { return areas }
        
        // Leave headroom so sizes can still vary; never require more than the list can give.
        let floorShare = min(max(minShare, 0), 0.85 / Double(areas.count))
        var fractions = areas.map { $0 / total }
        
        var deficit = 0.0
        for index in fractions.indices where fractions[index] < floorShare {
            deficit += floorShare - fractions[index]
            fractions[index] = floorShare
        }
        
        guard deficit > 0 else { return areas }
        
        let donorIndices = fractions.indices.filter { fractions[$0] > floorShare }
        let donorExtra = donorIndices.reduce(0.0) { $0 + (fractions[$1] - floorShare) }
        guard donorExtra > 0 else { return areas }
        
        for index in donorIndices {
            let weight = (fractions[index] - floorShare) / donorExtra
            fractions[index] -= deficit * weight
        }
        
        return fractions.map { $0 * total }
    }
    
    /// Lays the tiles out as full width rows that consume the whole canvas, so
    /// neighboring cells share edges with only the stroke between them.
    private static func rowFrames(areas: [Double], side: CGFloat) -> [CGRect] {
        let width = Double(side)
        let scale = width * width / max(areas.reduce(0, +), 1e-9)
        let scaledAreas = areas.map { $0 * scale }
        
        var frames: [CGRect] = []
        var y = 0.0
        var index = 0
        
        while index < scaledAreas.count {
            var count = 1
            var rowArea = scaledAreas[index]
            var aspect = averageAspect(of: scaledAreas[index..<(index + count)], width: width)
            
            while index + count < scaledAreas.count {
                let candidate = averageAspect(of: scaledAreas[index..<(index + count + 1)], width: width)
                guard candidate <= aspect else { break }
                
                aspect = candidate
                rowArea += scaledAreas[index + count]
                count += 1
            }
            
            let isLastRow = index + count >= scaledAreas.count
            let height = isLastRow ? max(width - y, rowArea / width) : rowArea / width
            var x = 0.0
            
            for offset in 0..<count {
                let isLastInRow = offset == count - 1
                let tileWidth = isLastInRow ? width - x : scaledAreas[index + offset] / height
                frames.append(
                    CGRect(x: x, y: y, width: max(tileWidth, 0), height: max(height, 0))
                )
                x += tileWidth
            }
            
            y += height
            index += count
        }
        
        return frames
    }
    
    private static func averageAspect(of areas: ArraySlice<Double>, width: Double) -> Double {
        let rowArea = areas.reduce(0, +)
        guard rowArea > 0, width > 0 else { return .infinity }
        
        let height = rowArea / width
        let total = areas.reduce(0.0) { partial, area in
            let tileWidth = area / height
            guard tileWidth > 0 else { return partial + .infinity }
            return partial + max(tileWidth / height, height / tileWidth)
        }
        
        return total / Double(areas.count)
    }
    
    private static func marketCapSpans(coins: [Toplist], minSpan: Int, maxSpan: Int) -> [Int] {
        let caps = coins.map { max($0.market_cap ?? 0, 1.0) }
        guard let maxCap = caps.max(), maxCap > 0 else {
            return Array(repeating: minSpan, count: coins.count)
        }
        
        let minCap = caps.min() ?? 1
        let maxLog = log(maxCap)
        let minLog = log(minCap)
        let logRange = max(maxLog - minLog, 1e-9)
        
        return caps.map { cap in
            let logRatio = (log(cap) - minLog) / logRange
            let curved = pow(logRatio, 0.9)
            let span = minSpan + Int((curved * Double(maxSpan - minSpan)).rounded())
            return max(minSpan, min(maxSpan, span))
        }
    }
}
