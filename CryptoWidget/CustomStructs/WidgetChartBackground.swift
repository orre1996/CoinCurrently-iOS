//
//  WidgetChartBackground.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 4/7/25.
//

import SwiftUI

struct WidgetChartBackground: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            WidgetChartBackgroundPathHorizontal()
                .stroke(.tertiary)
            
            WidgetChartBackgroundPathVertical()
                .stroke(.tertiary)
        }
    }
}

struct WidgetChartBackgroundPathHorizontal: Shape {
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0.25 * rect.height))
            path.addLine(to: CGPoint(x: 1 * rect.width, y: 0.25 * rect.height))
            
            path.move(to: CGPoint(x: 0, y: 0.5 * rect.height))
            path.addLine(to: CGPoint(x: 1 * rect.width, y: 0.5 * rect.height))
            
            path.move(to: CGPoint(x: 0, y: 0.75 * rect.height))
            path.addLine(to: CGPoint(x: 1 * rect.width, y: 0.75 * rect.height))
        }
    }
}

struct WidgetChartBackgroundPathVertical: Shape {
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0.25 * rect.width, y: 0 * rect.height))
            path.addLine(to: CGPoint(x: 0.25 * rect.width, y: 1 * rect.height))
            
            path.move(to: CGPoint(x: 0.5 * rect.width, y: 0 * rect.height))
            path.addLine(to: CGPoint(x: 0.5 * rect.width, y: 1 * rect.height))
            
            path.move(to: CGPoint(x: 0.75 * rect.width, y: 0 * rect.height))
            path.addLine(to: CGPoint(x: 0.75 * rect.width, y: 1 * rect.height))
            
        }
    }
}

struct WatchChartBackgroundPathVertical: Shape {
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0.25 * rect.width, y: 0 * rect.height))
            path.addLine(to: CGPoint(x: 0.25 * rect.width, y: 1 * rect.height))
            
            path.move(to: CGPoint(x: 0.5 * rect.width, y: 0 * rect.height))
            path.addLine(to: CGPoint(x: 0.5 * rect.width, y: 1 * rect.height))
            
            path.move(to: CGPoint(x: 0.75 * rect.width, y: 0 * rect.height))
            path.addLine(to: CGPoint(x: 0.75 * rect.width, y: 1 * rect.height))

        }
    }
}
