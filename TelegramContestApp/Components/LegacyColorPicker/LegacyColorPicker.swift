//
//  LegacyColorPicker.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 31.10.2022.
//

import Foundation
import UIKit

protocol LegacyColorPickerDelegate: AnyObject {
    func legacyColorPicker(_ picker: LegacyColorPicker, didSelect color: UIColor)
    func legacyColorPickerDidDismiss(_ picker: LegacyColorPicker)
}

final class LegacyColorPicker: UIView {
    private enum Constants {
        static let bubbleViewSize: CGSize = CGSize(width: 20, height: 20)
        static let bubblePointViewSize: CGSize = CGSize(width: 8, height: 8)
        
        static let gradientLayerWidth: CGFloat = .xxs
        
        static let xTranslation: CGFloat = 40
        static let trackingBubbleTransform: CGAffineTransform = CGAffineTransform(translationX: -Constants.xTranslation, y: .zero)
            .scaledBy(x: 1.5, y: 1.5)
    }
    
    var delegate: LegacyColorPickerDelegate?
    private let slider = UISlider().forAutoLayout()
    private let previewBubbleView: UIView = UIView().forAutoLayout()
    private let previewBubblePointView: UIView = UIView().forAutoLayout()
    private let colorGradientLayer: CAGradientLayer = CAGradientLayer()
    private var isTracking: Bool = false {
        didSet {
            updateTrackingStatus()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        colorGradientLayer.frame = CGRect(
            x: bounds.width - Constants.bubbleViewSize.width,
            y: .zero + Constants.bubbleViewSize.height.half,
            width: Constants.gradientLayerWidth,
            height: bounds.height - Constants.bubbleViewSize.height
        )
        slider.frame = colorGradientLayer.frame
        previewBubbleView.frame.origin = CGPoint(
            x: bounds.width - Constants.bubbleViewSize.width - (Constants.bubbleViewSize.width - Constants.gradientLayerWidth).half,
            y: bounds.height - Constants.bubbleViewSize.height - (CGFloat(slider.value) * colorGradientLayer.frame.height)
        )
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hittedView = super.hitTest(point, with: event)
        if hittedView == previewBubbleView || hittedView == previewBubblePointView {
            return slider
        } else {
            return hittedView
        }
    }
    
    private func commonInit() {
        addSubviews()
        makeConstraints()
        setupSlider()
        setupBubblePreview()
        setupGradientLayer()
    }
    
    private func addSubviews() {
        layer.addSublayer(colorGradientLayer)
        addSubview(slider)
        addSubview(previewBubbleView)
        previewBubbleView.addSubview(previewBubblePointView)
    }
    
    private func makeConstraints() {
        [
            previewBubbleView.widthAnchor.constraint(equalToConstant: Constants.bubbleViewSize.width),
            previewBubbleView.heightAnchor.constraint(equalToConstant: Constants.bubbleViewSize.height),
            
            previewBubblePointView.widthAnchor.constraint(equalToConstant: Constants.bubblePointViewSize.width),
            previewBubblePointView.heightAnchor.constraint(equalToConstant: Constants.bubblePointViewSize.height),
            previewBubblePointView.centerXAnchor.constraint(equalTo: previewBubbleView.centerXAnchor),
            previewBubblePointView.centerYAnchor.constraint(equalTo: previewBubbleView.centerYAnchor),
        ].activate()
    }
    
    private func setupSlider() {
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(UIImage(), for: .normal)
        
        slider.addTarget(self, action: #selector(handleSliderValueChange), for: .valueChanged)
        slider.addTarget(self, action: #selector(handleSliderEndTracking), for: [.touchUpInside,.touchUpOutside])
        slider.addTarget(self, action: #selector(handleSliderStartTracking), for: .touchDown)
        
        slider.transform = CGAffineTransform(rotationAngle: 3 * .pi / 2)
    }
    
    private func setupBubblePreview() {
        previewBubbleView.backgroundColor = .white
        previewBubbleView.layer.cornerRadius = Constants.bubbleViewSize.height.half
        previewBubblePointView.layer.cornerRadius = Constants.bubblePointViewSize.height.half
    }
    
    private func setupGradientLayer() {
        colorGradientLayer.cornerRadius = Constants.gradientLayerWidth.half
        colorGradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.black.cgColor,
            UIColor.brown.cgColor,
            UIColor.yellow.cgColor,
            UIColor.green.cgColor,
            UIColor.cyan.cgColor,
            UIColor.blue.cgColor,
            UIColor.purple.cgColor,
            UIColor.red.cgColor
        ]
        colorGradientLayer.locations = nil
        colorGradientLayer.startPoint = CGPoint(
            x: .one.half,
            y: .one
        )
        colorGradientLayer.endPoint = CGPoint(
            x: .one.half,
            y: .zero
        )
    }
    
    private func updateTrackingStatus() {
        UIView.animate(
            withDuration: Durations.half,
            delay: .zero,
            options: .curveEaseOut,
            animations: {
                self.previewBubbleView.transform = self.isTracking ? Constants.trackingBubbleTransform : .identity
            },
            completion: nil
        )
    }
    
    @objc private func handleSliderValueChange() {
        guard let interpolatedColor = interpolatedColor(for: slider.value) else { return }
        
        previewBubblePointView.backgroundColor = interpolatedColor
        delegate?.legacyColorPicker(self, didSelect: interpolatedColor)
    }
    
    private func interpolatedColor(for value: Float) -> UIColor? {
        guard let colorsCount = colorGradientLayer.colors?.count else { return nil }
        let floatValue = CGFloat(value)
        let pointY = floatValue * colorGradientLayer.frame.height
        previewBubbleView.frame.origin.y = bounds.height - Constants.bubbleViewSize.height - pointY
        let step = layer.frame.height / CGFloat(colorsCount)
        let index = Int(pointY / step)
        let offset = pointY - CGFloat(index) * step
        
        guard let rawLeftColor = colorGradientLayer.colors?[safe: index] else { return nil }
        let leftColor = UIColor(cgColor: rawLeftColor as! CGColor)
        
        if let rawRightColor = colorGradientLayer.colors?[safe: index + 1] {
            // справа еще есть цвет
            let rightColor = UIColor(cgColor: rawRightColor as! CGColor)
            let leftComponents = leftColor.components
            let rightComponents = rightColor.components
    
            return UIColor(
                red: leftComponents.red + (rightComponents.red - leftComponents.red) * offset / step,
                green: leftComponents.green + (rightComponents.green - leftComponents.green) * offset / step,
                blue: leftComponents.blue + (rightComponents.blue - leftComponents.blue) * offset / step,
                alpha: .one
            )
        } else {
            // левый цвет - последний
            return leftColor
        }
    }
    
    @objc private func handleSliderEndTracking() {
        if isTracking {
            isTracking = false
        }
    }
    
    @objc private func handleSliderStartTracking() {
        if !isTracking {
            isTracking = true
        }
    }
}

private extension UIColor {
    struct ColorComponents {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }
    
    var components: ColorComponents {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        return ColorComponents(red: red, green: green, blue: blue)
    }
}
