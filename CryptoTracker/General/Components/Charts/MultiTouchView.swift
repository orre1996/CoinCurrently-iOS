//
//  MultiTouchView.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2023-08-08.
//

import SwiftUI

struct MultiTouchView: UIViewRepresentable {
    var tappedCallback: (([CGPoint]) -> Void)

    func makeUIView(context: UIViewRepresentableContext<MultiTouchView>) -> MultiTouchView.UIViewType {
        let v = UIView(frame: .zero)
        v.isAccessibilityElement = false
        v.accessibilityElementsHidden = true
        let gesture = MultiTouchGestureRecognizer(target: context.coordinator, tappedCallback: tappedCallback)
        v.addGestureRecognizer(gesture)
        return v
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<MultiTouchView>) { }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.isAccessibilityElement = false
        uiView.accessibilityElementsHidden = true
    }
}

public class MultiTouchGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    private var trackedTouches = [UITouch: CGPoint]()
    
    var tappedCallback: ([CGPoint]) -> Void
    
    init(target: Any?, tappedCallback: @escaping ([CGPoint]) -> ()) {
        self.tappedCallback = tappedCallback
        super.init(target: target, action: nil)
        self.delegate = self
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .began
        
        for touch in touches {
            trackedTouches[touch] = touch.location(in: view)
        }
    
        tappedCallback(Array(trackedTouches.map({ $0.value }).sorted(by: { $0.x < $1.x }).prefix(2)))
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .changed
        
        for touch in touches {
            trackedTouches[touch] = touch.location(in: view)
        }
        
        tappedCallback(Array(trackedTouches.map({ $0.value }).sorted(by: { $0.x < $1.x }).prefix(2)))
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            trackedTouches[touch] = nil
        }
        
        if trackedTouches.count == 0 {
            state = .ended
        }
        
        tappedCallback(Array(trackedTouches.map({ $0.value }).sorted(by: { $0.x < $1.x }).prefix(2)))
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
        
        for touch in touches {
            trackedTouches[touch] = nil
        }
        
        tappedCallback(Array(trackedTouches.map({ $0.value }).sorted(by: { $0.x < $1.x }).prefix(2)))
    }

    public override func reset() {
        super.reset()

        self.trackedTouches = [:]
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
