//
//  Slider.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 29.10.2022.
//

import Foundation
import UIKit

protocol SliderDelegate: AnyObject {
    func valueChanged(_ slider: Slider, to newValue: Float)
    func didEndTracking(_ slider: Slider, with finalValue: Float)
    func didStartTracking(_ slider: Slider, with initialValue: Float)
}

extension SliderDelegate {
    func didEndTracking(_ slider: Slider, with finalValue: Float) {}
    func didStartTracking(_ slider: Slider, with initialValue: Float) {}
}

final class Slider: UISlider {
    private enum Constants {
        static let startRadius: CGFloat = 1
        static let endRadius: CGFloat = 10
        static let height: CGFloat = 32
        static let alpha: CGFloat = 0.2
    }
    
    override var value: Float {
        get {
            return super.value
        }
        set {
            previouslyEmittedValue = newValue
            super.value = newValue
        }
    }
    
    var threshold: Float = 0.00
    weak var delegate: SliderDelegate?
    
    private var previouslyEmittedValue: Float?
    private let transparentBackground: Bool
    
    init(transparentBackground: Bool = false) {
        self.transparentBackground = transparentBackground
        super.init(frame: .zero)
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear
        addTarget(self, action: #selector(handleSliderValueChange), for: .valueChanged)
        addTarget(self, action: #selector(handleSliderEndTracking), for: [.touchUpInside,.touchUpOutside])
        addTarget(self, action: #selector(handleSliderStartTracking), for: .touchDown)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let path = UIBezierPath()
        path.addArc(
            withCenter: CGPoint(
                x: rect.minX + Constants.startRadius,
                y: rect.midY
            ),
            radius: Constants.startRadius,
            startAngle: 3 * .pi / 2,
            endAngle: .pi / 2,
            clockwise: false
        )
        path.addLine(
            to: CGPoint(
                x: rect.maxX - Constants.endRadius,
                y: rect.midY + Constants.endRadius
            )
        )
        path.addArc(
            withCenter: CGPoint(
                x: rect.maxX - Constants.endRadius,
                y: rect.midY
            ),
            radius: Constants.endRadius,
            startAngle: .pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: false
        )
        path.close()
        UIColor.white.withAlphaComponent(transparentBackground ? .zero : Constants.alpha).setFill()
        path.fill()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.height)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: Constants.height)
    }
    
    @objc private func handleSliderValueChange() {
        if let previouslyEmittedValue = previouslyEmittedValue {
            if abs(previouslyEmittedValue - value) > threshold {
                delegate?.valueChanged(self, to: value)
                self.previouslyEmittedValue = value
            }
        } else {
            delegate?.valueChanged(self, to: value)
            self.previouslyEmittedValue = value
        }
    }
    
    @objc private func handleSliderEndTracking() {
        delegate?.didEndTracking(self, with: value)
    }
    
    @objc private func handleSliderStartTracking() {
        delegate?.didStartTracking(self, with: value)
    }
}
