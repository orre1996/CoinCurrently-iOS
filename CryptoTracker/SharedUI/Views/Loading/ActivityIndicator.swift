//
//  ActivityIndicator.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-07-22.
//

import SwiftUI

struct ActivityIndicator: View {
    @ScaledMetric private var scale: CGFloat = 1

    @State var degress = 0.0
    @State var size: CGFloat = 32

    @State private var timer: Timer?
    
    var color: Color?
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.6)
            .stroke(color ?? Color.onSurface, lineWidth: 3.0)
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: degress))
            .onAppear {
                start()
            }
    }
    
    func start() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    self.degress += 10.0
                }
            }
        }
    }
}
