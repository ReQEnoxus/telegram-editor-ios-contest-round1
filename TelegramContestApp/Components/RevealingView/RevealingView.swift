//
//  RevealingView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import Foundation
import UIKit

final class RevealingView<Wrapped: UIView>: UIView, CAAnimationDelegate {
    let wrapped: Wrapped
    private let revealingLayer: CAGradientLayer = CAGradientLayer()
    private var revealCompletionBlock: Producer<Void>?
    private let revealConfiguration: RevealConfiguration
    
    private let animationKey: String = "revealAnimation"
    
    func reveal(completion: Producer<Void>? = nil) {
        revealCompletionBlock = completion
        
        let animation = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.locations))
        animation.duration = revealConfiguration.animationDuration
        animation.timingFunction = revealConfiguration.timingFunction
        let targetLocations = [
            NSNumber(floatLiteral: .zero),
            NSNumber(floatLiteral: 1.0 - revealConfiguration.gradientLengthMultiple / (1 + revealConfiguration.gradientLengthMultiple.doubled)),
            NSNumber(floatLiteral: 1)
        ]
        
        animation.fromValue = [
            NSNumber(floatLiteral: .zero),
            NSNumber(floatLiteral: .zero),
            NSNumber(floatLiteral: revealConfiguration.gradientLengthMultiple / (1 + revealConfiguration.gradientLengthMultiple.doubled))
        ]
        animation.toValue = targetLocations
        animation.fillMode = .both
        animation.isRemovedOnCompletion = true
        revealingLayer.add(animation, forKey: animationKey)
        revealingLayer.locations = targetLocations
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag && anim == revealingLayer.animation(forKey: animationKey) {
            revealCompletionBlock?()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        revealingLayer.frame = bounds
    }
    
    init(wrapped: Wrapped = Wrapped(), revealConfiguration: RevealConfiguration = RevealConfiguration()) {
        self.wrapped = wrapped.forAutoLayout()
        self.revealConfiguration = revealConfiguration
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        addSubviews()
        makeConstraints()
        setupGradient()
        layer.mask = revealingLayer
    }
    
    private func addSubviews() {
        addSubview(wrapped)
    }
    
    private func makeConstraints() {
        [
            wrapped.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapped.topAnchor.constraint(equalTo: topAnchor),
            wrapped.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrapped.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    private func setupGradient() {
        revealingLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(.zero).cgColor
        ]
        revealingLayer.startPoint = CGPoint(
            x: .one.half,
            y: -revealConfiguration.gradientLengthMultiple
        )
        revealingLayer.endPoint = CGPoint(
            x: .one.half,
            y: .one + revealConfiguration.gradientLengthMultiple
        )
    }
}
