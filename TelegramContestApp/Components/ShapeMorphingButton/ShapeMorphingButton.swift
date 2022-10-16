//
//  ShapeMorphingButton.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 15.10.2022.
//

import Foundation
import UIKit

final class ShapeMorphingButton<ShapeKey: Hashable>: UIButton {
    
    private(set) var currentShape: ShapeKey?
    
    private var shapes: [ShapeKey: [Shape]] = [:]
    private var shapeLayers: [CAShapeLayer] = []
    
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
        shapeLayers.forEach { $0.frame = bounds }
        guard let currentShape = currentShape else { return }
        morph(to: currentShape, animated: false)
    }
    
    func setShapes(shapes: [ShapeKey: [Shape]], initial: ShapeKey) {
        self.shapes = shapes
        updateLayers(for: Array(shapes.values))
        morph(to: initial, animated: false)
        currentShape = initial
    }
    
    func setShape(_ shape: ShapeKey, animated: Bool) {
        morph(to: shape, animated: animated)
        currentShape = shape
    }
    
    private func commonInit() {
//        layer.addSublayer(shapeLayer)
    }
    
    private func updateLayers(for shapes: [[Shape]]) {
        guard let maxCount = shapes.max(by: { $0.count < $1.count })?.count else { return }
        if shapeLayers.count < maxCount {
            let newLayers = (.zero ..< maxCount - shapeLayers.count).map { _ in CAShapeLayer() }
            newLayers.forEach { layer.addSublayer($0) }
            shapeLayers.append(contentsOf: newLayers)
        } else if shapeLayers.count > maxCount {
            let oddLayers = shapeLayers.suffix(shapeLayers.count - maxCount)
            oddLayers.forEach { $0.removeFromSuperlayer() }
            shapeLayers.removeLast(shapeLayers.count - maxCount)
        }
        shapeLayers.forEach { $0.path = nil }
    }
    
    private func morph(to key: ShapeKey, animated: Bool) {
        guard let currentKey = currentShape,
              let currentShapes = shapes[currentKey],
              let targetShapes = shapes[key] else { return }
        shapeLayers.enumerated().forEach { index, layer in
            guard let shape = targetShapes[safe: index] else {
                layer.isHidden = true
                return
            }
            layer.isHidden = false
            layer.lineCap = shape.lineCap
            
            
            if animated {
                layer.applyAnimation(from: currentShapes[safe: index], to: shape)
            }
            layer.path = shape.draw(in: bounds).cgPath
            layer.strokeColor = shape.strokeColor
            layer.fillColor = shape.fillColor
            layer.lineWidth = shape.lineWidth(for: bounds)
        }
    }
}

private extension CAShapeLayer {
    func applyAnimation(from shape: Shape?, to targetShape: Shape) {
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
