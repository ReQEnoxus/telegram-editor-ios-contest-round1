//
//  SweepingButton.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import UIKit

final class SweepingButton: UIButton {
    private enum Constants {
        static let widthMultiplier: CGFloat = 1 / 2.5
        
        static let whiteAlphaComponent: CGFloat = 0.2
        static let whiteAlphaCenterComponent: CGFloat = 0.22
        static let whiteAlphaEndComponent: CGFloat = 0.19
        
        static let fullAnimationDuration: TimeInterval = 4
        static let sweepDuration: TimeInterval = 1.7
        
        static let firstStep: Double = 0.45
        static let middleStep: Double = 0.55
        static let lastStep: Double = 0.65
        
        static let highlightedAlpha: CGFloat = 0.9
        
        static let animationKey = "sweepAnimation"
    }
    private let gradientLayer = CAGradientLayer()
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: Durations.third) {
                self.backgroundColor = self.isHighlighted ? self.backgroundColor?.withAlphaComponent(Constants.highlightedAlpha) : self.backgroundColor?.withAlphaComponent(.one)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.removeAnimation(forKey: Constants.animationKey)
        gradientLayer.frame = CGRect(
            origin: CGPoint(
                x: -bounds.width * Constants.widthMultiplier,
                y: .zero
            ),
            size: CGSize(
                width: bounds.width * Constants.widthMultiplier,
                height: bounds.height
            )
        )
        
        startAnimation()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.masksToBounds = true
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = .xxs
        contentEdgeInsets = UIEdgeInsets(top: .xs, left: .zero, bottom: .xs, right: .zero)
        setupGradient()
    }
    
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(.zero).cgColor,
            UIColor.white.withAlphaComponent(Constants.whiteAlphaComponent).cgColor,
            UIColor.white.withAlphaComponent(Constants.whiteAlphaCenterComponent).cgColor,
            UIColor.white.withAlphaComponent(Constants.whiteAlphaEndComponent).cgColor,
            UIColor.white.withAlphaComponent(.zero).cgColor
        ]
        gradientLayer.startPoint = CGPoint(
            x: .zero,
            y: .one.half
        )
        gradientLayer.endPoint = CGPoint(
            x: .one,
            y: .one.half
        )
        gradientLayer.locations = [
            NSNumber(floatLiteral: .zero),
            NSNumber(floatLiteral: Constants.firstStep),
            NSNumber(floatLiteral: Constants.middleStep),
            NSNumber(floatLiteral: Constants.lastStep),
            NSNumber(floatLiteral: 1)
        ]
    }
    
    private func startAnimation() {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CAGradientLayer.position))
        animation.duration = Constants.fullAnimationDuration
        animation.repeatCount = .greatestFiniteMagnitude
        animation.fillMode = .both
        animation.beginTime = Constants.sweepDuration
        animation.values = [
            CGPoint(
                x: gradientLayer.frame.minX,
                y: bounds.midY
            ),
            CGPoint(
                x: bounds.width + gradientLayer.frame.width,
                y: bounds.midY
            ),
            CGPoint(
                x: bounds.width + gradientLayer.frame.width,
                y: bounds.midY
            )
        ]
        animation.keyTimes = [
            NSNumber(floatLiteral: .zero),
            NSNumber(floatLiteral: Constants.sweepDuration / Constants.fullAnimationDuration),
            NSNumber(floatLiteral: 1)
        ]
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear)
        ]

        gradientLayer.add(animation, forKey: Constants.animationKey)
    }
}
