//
//  DoubleClickGestureRecognizer.swift
//  MeteoBar
//
//  Created by Mike Manzo on 2/20/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

///
///  DoubleClickGestureRecognizer.swift
/// Gesture recognizer to detect two clicks and one click without having a massive delay or having
/// to implement all this annoying `requireFailureOf` boilerplate code
///
///  [Attribution](https://stackoverflow.com/questions/2181033/catching-double-click-in-cocoa-osx#)
///
final class QLDoubleClickGestureRecognizer: NSClickGestureRecognizer {
    
    private let _action: Selector
    private let _doubleAction: Selector
    private var _clickCount: Int = 0
    
    override var action: Selector? {
        get {
            return nil /// prevent base class from performing any actions
        } set {
            if newValue != nil { // if they are trying to assign an actual action
                fatalError("Only use init(target:action:doubleAction) for assigning actions")
            }
        }
    }
    
    required init(target: AnyObject, action: Selector, doubleAction: Selector) {
        _action = action
        _doubleAction = doubleAction
        super.init(target: target, action: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(target:action:doubleAction) is only support atm")
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        _clickCount += 1
        let delayThreshold = 0.15 // fine tune this as needed
        perform(#selector(_resetAndPerformActionIfNecessary), with: nil, afterDelay: delayThreshold)
        if _clickCount == 2 {
            _ = target?.perform(_doubleAction)
        }
    }
    
    @objc private func _resetAndPerformActionIfNecessary() {
        if _clickCount == 1 {
            _ = target?.perform(_action)
        }
        _clickCount = 0
    }
}
