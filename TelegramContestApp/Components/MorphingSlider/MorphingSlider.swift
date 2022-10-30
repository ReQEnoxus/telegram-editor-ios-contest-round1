//
//  MorphingSlider.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 30.10.2022.
//

import Foundation
import UIKit

// офигеть, я это сделал)
final class MorphingSlider: UIView {
    private enum Constants {
        static let sliderStartRadius: CGFloat = 1
        static let sliderThumbSize: CGSize = CGSize(width: 27.5, height: 27.5)
        static let segmentControlCornerRadius: CGFloat = 16
        
        static let sliderBackgroundAlpha: CGFloat = 0.2
        
        static let thumbAnimationSliderKey: String = "thumbAnimationSlider"
        static let thumbAnimationSegmentKey: String = "thumbAnimationSegment"
        static let backgroundAnimationSliderKey: String = "backgroundAnimationSliderKey"
        static let backgroundAnimationSegmentKey: String = "backgroundAnimationSegmentKey"
        
        static let animationDuration: TimeInterval = Durations.single
    }
    
    enum Mode {
        case slider
        case segmentedControl
    }
    
    struct Model {
        let sliderValue: Float
        let segmentedControlModel: SegmentedControl.Model
    }
    
    private(set) var mode: Mode = .segmentedControl
    private(set) var slider = Slider(transparentBackground: true).forAutoLayout()
    private(set) var segmentedControl = SegmentedControl(transparentBackground: true).forAutoLayout()
    private var model: Model?
    
    private let thumbLayer: CAShapeLayer = CAShapeLayer()
    private let backgroundLayer: CAShapeLayer = CAShapeLayer()
    
    private var animatingForward: Bool = true
    
    func setMode(_ newMode: Mode) {
        guard newMode != mode else { return }
        let backgroundAnimationGroup = CAAnimationGroup()
        let sourceBackgroundPath = backgroundPath(for: mode, in: bounds)
        let targetBackgroundPath = backgroundPath(for: newMode, in: bounds)
        let sourceBackgroundColor = backgroundFillColor(for: mode).cgColor
        let targetBackgroundColor = backgroundFillColor(for: newMode).cgColor
        
        let sourceThumbPath = thumbPath(for: mode, in: bounds)
        let targetThumbPath = thumbPath(for: newMode, in: bounds)
        let sourceThumbColor = thumbFillColor(for: mode).cgColor
        let targetThumbColor = thumbFillColor(for: newMode).cgColor
        
        backgroundAnimationGroup.animations = [
            // background path
            createAnimation(
                keyPath: #keyPath(CAShapeLayer.path),
                fromValue: sourceBackgroundPath,
                toValue: targetBackgroundPath
            ),
            // background color
            createAnimation(
                keyPath: #keyPath(CAShapeLayer.fillColor),
                fromValue: sourceBackgroundColor,
                toValue: targetBackgroundColor
            )
            
        ]
        backgroundAnimationGroup.duration = Constants.animationDuration
        
        let thumbAnimationGroup = CAAnimationGroup()
        thumbAnimationGroup.animations = [
            // thumb path
            createAnimation(
                keyPath: #keyPath(CAShapeLayer.path),
                fromValue: sourceThumbPath,
                toValue: targetThumbPath
            ),
            // thumb color
            createAnimation(
                keyPath: #keyPath(CAShapeLayer.fillColor),
                fromValue: sourceThumbColor,
                toValue: targetThumbColor
            )
        ]
        thumbAnimationGroup.duration = Constants.animationDuration
        
        backgroundAnimationGroup.delegate = self
        thumbAnimationGroup.delegate = self
        
        switch newMode {
        case .slider:
            animatingForward = true
            withoutAnimation {
                thumbLayer.fillColor = sourceThumbColor
                thumbLayer.opacity = 1
                slider.alpha = .zero
                segmentedControl.selectionView.alpha = 0
                thumbLayer.path = sourceThumbPath
            }
            thumbLayer.add(thumbAnimationGroup, forKey: Constants.thumbAnimationSliderKey)
            thumbLayer.fillColor = targetThumbColor
            thumbLayer.path = targetThumbPath
            
            withoutAnimation {
                backgroundLayer.fillColor = sourceBackgroundColor
                backgroundLayer.path = sourceBackgroundPath
            }
            backgroundLayer.add(backgroundAnimationGroup, forKey: Constants.backgroundAnimationSliderKey)
            backgroundLayer.fillColor = targetBackgroundColor
            backgroundLayer.path = targetBackgroundPath
            
            withoutAnimation {
                segmentedControl.layer.opacity = 1
            }
            let segmentedControlAnimation = createAnimation(
                keyPath: #keyPath(CALayer.opacity),
                fromValue: 1,
                toValue: 0
            )
            segmentedControl.layer.add(segmentedControlAnimation, forKey: nil)
            segmentedControl.layer.opacity = 0
            
        case .segmentedControl:
            animatingForward = false
            
            withoutAnimation {
                thumbLayer.fillColor = sourceThumbColor
                thumbLayer.opacity = 1
                slider.alpha = .zero
                thumbLayer.path = sourceThumbPath
            }
            
            thumbLayer.add(thumbAnimationGroup, forKey: Constants.thumbAnimationSegmentKey)
            thumbLayer.fillColor = targetThumbColor
            thumbLayer.path = targetThumbPath
            
            withoutAnimation {
                backgroundLayer.fillColor = sourceBackgroundColor
                backgroundLayer.path = sourceBackgroundPath
            }
            
            backgroundLayer.add(backgroundAnimationGroup, forKey: Constants.backgroundAnimationSegmentKey)
            backgroundLayer.fillColor = targetBackgroundColor
            backgroundLayer.path = targetBackgroundPath
            
            withoutAnimation {
                segmentedControl.layer.opacity = 0
            }
            
            let segmentedControlAnimation = createAnimation(
                keyPath: #keyPath(CALayer.opacity),
                fromValue: 0,
                toValue: 1
            )
            segmentedControl.layer.add(segmentedControlAnimation, forKey: nil)
            segmentedControl.layer.opacity = 1
        }
        mode = newMode
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        backgroundLayer.path = backgroundPath(for: mode, in: bounds)
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
        addSubviews()
        makeConstraints()
        setupLayers()
        setupInitialState()
    }
    
    private func addSubviews() {
        layer.addSublayer(backgroundLayer)
        addSubview(slider)
        layer.addSublayer(thumbLayer)
        addSubview(segmentedControl)
    }
    
    private func setupLayers() {
        thumbLayer.fillColor = UIColor.white.cgColor
        thumbLayer.strokeColor = UIColor.clear.cgColor
        backgroundLayer.fillColor = Asset.Colors.dark.color.cgColor
        backgroundLayer.strokeColor = UIColor.clear.cgColor
    }
    
    private func setupInitialState() {
        slider.alpha = .zero
        thumbLayer.opacity = .zero
        segmentedControl.alpha = .one
    }
    
    private func backgroundPath(for mode: Mode, in bounds: CGRect) -> CGPath {
        switch mode {
        case .slider:
            let path = UIBezierPath()
            path.addArc(
                withCenter: CGPoint(
                    x: bounds.minX + Constants.sliderStartRadius,
                    y: bounds.midY
                ),
                radius: Constants.sliderStartRadius,
                startAngle: .pi / 2,
                endAngle: 3 * .pi / 2,
                clockwise: true
            )
            
            path.addLine(
                to: CGPoint(
                    x: bounds.maxX - Constants.segmentControlCornerRadius,
                    y: bounds.minY
                )
            )
            
            path.addArc(
                withCenter: CGPoint(
                    x: bounds.maxX - Constants.segmentControlCornerRadius,
                    y: bounds.midY
                ),
                radius: Constants.segmentControlCornerRadius,
                startAngle: 3 * .pi / 2,
                endAngle: .pi / 2,
                clockwise: true
            )
            
            path.close()
            return path.cgPath
            
        case .segmentedControl:
            let path = UIBezierPath()
            
            path.addArc(
                withCenter: CGPoint(
                    x: bounds.minX + Constants.segmentControlCornerRadius,
                    y: bounds.midY
                ),
                radius: Constants.segmentControlCornerRadius,
                startAngle: .pi / 2,
                endAngle: 3 * .pi / 2,
                clockwise: true
            )
            
            path.addLine(
                to: CGPoint(
                    x: bounds.maxX - Constants.segmentControlCornerRadius,
                    y: bounds.minY
                )
            )
            
            path.addArc(
                withCenter: CGPoint(
                    x: bounds.maxX - Constants.segmentControlCornerRadius,
                    y: bounds.midY
                ),
                radius: Constants.segmentControlCornerRadius,
                startAngle: 3 * .pi / 2,
                endAngle: .pi / 2,
                clockwise: true
            )
            
            path.close()
            return path.cgPath
        }
    }
    
    private func thumbPath(for mode: Mode, in bounds: CGRect) -> CGPath {
        switch mode {
        case .slider:
            return UIBezierPath(
                roundedRect: CGRect(
                    x: currentSliderThumbCenterPosition(in: bounds).x - Constants.sliderThumbSize.width.half,
                    y: currentSliderThumbCenterPosition(in: bounds).y - Constants.sliderThumbSize.height.half,
                    width: Constants.sliderThumbSize.width,
                    height: Constants.sliderThumbSize.height
                ),
                cornerRadius: Constants.sliderThumbSize.height.half
            ).cgPath
            
        case .segmentedControl:
            return UIBezierPath(
                roundedRect: segmentedControl.selectionView.frame,
                cornerRadius: Constants.segmentControlCornerRadius
            ).cgPath
        }
    }
    
    private func backgroundFillColor(for mode: Mode) -> UIColor {
        switch mode {
        case .slider:
            return .white.withAlphaComponent(Constants.sliderBackgroundAlpha)
        case .segmentedControl:
            return Asset.Colors.dark.color
        }
    }
    
    private func thumbFillColor(for mode: Mode) -> UIColor {
        switch mode {
        case .slider:
            return .white
        case .segmentedControl:
            return Asset.Colors.darkSelected.color
        }
    }
    
    private func currentSliderThumbCenterPosition(in bounds: CGRect) -> CGPoint {
        let sliderRatio = (slider.value - slider.minimumValue) / (slider.maximumValue - slider.minimumValue)
        
        return CGPoint(
            x: Constants.sliderThumbSize.width.half + CGFloat(sliderRatio) * (bounds.width - Constants.sliderThumbSize.width),
            y: bounds.midY
        )
    }
    
    private func makeConstraints() {
        [
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.topAnchor.constraint(equalTo: topAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    private func createAnimation(keyPath: String, fromValue: Any, toValue: Any) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.duration = Constants.animationDuration
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.fillMode = .both
        
        return animation
    }
    
    private func withoutAnimation(_ action: Producer<Void>) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        action()
        CATransaction.commit()
    }
}

extension MorphingSlider: Configurable {
    func configure(with object: Any) {
        guard let model = object as? MorphingSlider.Model else { return }
        self.model = model
        segmentedControl.configure(with: model.segmentedControlModel)
        slider.value = model.sliderValue
    }
}

extension MorphingSlider: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if animatingForward {
            slider.alpha = 1
            withoutAnimation {
                thumbLayer.opacity = 0
            }
        } else {
            segmentedControl.selectionView.alpha = 1
            withoutAnimation {
                thumbLayer.opacity = 0
            }
            slider.alpha = .zero
        }
    }
}
