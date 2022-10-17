//
//  CAShapeLayer+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 17.10.2022.
//

import Foundation
import QuartzCore

extension CAShapeLayer {
    func morph(from shape: Shape?, to targetShape: Shape, animated: Bool = true) {
        if animated {
            let group = CAAnimationGroup()
            group.animations = [
                animationObject(
                    from: shape?.strokeColor,
                    to: targetShape.strokeColor,
                    keyPath: #keyPath(CAShapeLayer.strokeColor)
                ),
                animationObject(
                    from: shape?.fillColor,
                    to: targetShape.fillColor,
                    keyPath: #keyPath(CAShapeLayer.fillColor)
                ),
                animationObject(
                    from: shape?.lineWidth(for: bounds),
                    to: targetShape.lineWidth(for: bounds),
                    keyPath: #keyPath(CAShapeLayer.lineWidth)
                ),
                animationObject(
                    from: shape?.draw(in: bounds),
                    to: targetShape.draw(in: bounds),
                    keyPath: #keyPath(CAShapeLayer.path)
                )
            ]
            group.duration = Durations.half
            
            add(group, forKey: nil)
        }
        
        lineCap = targetShape.lineCap
        path = targetShape.draw(in: bounds).cgPath
        strokeColor = targetShape.strokeColor
        fillColor = targetShape.fillColor
        lineWidth = targetShape.lineWidth(for: bounds)
    }
    
    private func animationObject(from value: Any?, to targetValue: Any?, keyPath: String) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = value
        animation.toValue = targetValue
        animation.duration = Durations.half
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .both
        
        return animation
    }
}
