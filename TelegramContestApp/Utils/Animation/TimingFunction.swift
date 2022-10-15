//
//  TimingFunction.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 14.10.2022.
//

import UIKit

struct TimingFunction {
    
    var controlPoint1: CGPoint {
        didSet { updateUnitBezier() }
    }
    
    var controlPoint2: CGPoint {
        didSet { updateUnitBezier() }
    }
    
    var duration: CGFloat {
        didSet { updateEpsilon() }
    }
    
    static func epsilon(for duration: CGFloat) -> CGFloat {
        return CGFloat(1.0 / (200.0 * duration))
    }
    
    private var unitBezier: UnitBezier
    private var epsilon: CGFloat
    
    public init(controlPoint1: CGPoint, controlPoint2: CGPoint, duration: CGFloat = 1.0) {
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
        self.duration = duration
        self.unitBezier = .init(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        self.epsilon = TimingFunction.epsilon(for: duration)
    }
    
    func progress(at fractionComplete: CGFloat) -> CGFloat {
        return unitBezier.value(for: fractionComplete, epsilon: epsilon)
    }
    
    mutating private func updateUnitBezier() {
        unitBezier = UnitBezier(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }
    
    mutating private func updateEpsilon() {
        epsilon = TimingFunction.epsilon(for: duration)
    }
}

extension TimingFunction {
    init(timingParameters: UICubicTimingParameters, duration: CGFloat = 1.0) {
        self.init(
            controlPoint1: timingParameters.controlPoint1,
            controlPoint2: timingParameters.controlPoint2,
            duration: duration
        )
    }
}
