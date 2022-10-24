//
//  RevealConfiguration.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import Foundation
import CoreGraphics
import QuartzCore

struct RevealConfiguration {
    let animationDuration: TimeInterval
    let gradientLengthMultiple: CGFloat
    let timingFunction: CAMediaTimingFunction
    
    init(
        animationDuration: TimeInterval = Durations.double,
        gradientLengthMultiple: CGFloat = 0.2,
        timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeOut)
    ) {
        self.animationDuration = animationDuration
        self.gradientLengthMultiple = gradientLengthMultiple
        self.timingFunction = timingFunction
    }
}
