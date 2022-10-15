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
    
    private var shapes: [ShapeKey: Shape] = [:]
    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.lineCap = .round
        
        return layer
    }()
    
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
        shapeLayer.frame = bounds
        guard let currentShape = currentShape else { return }
        morph(to: currentShape, animated: false)
    }
    
    func setShapes(shapes: [ShapeKey: Shape], initial: ShapeKey) {
        self.shapes = shapes
        morph(to: initial, animated: false)
        currentShape = initial
    }
    
    func setShape(_ shape: ShapeKey, animated: Bool) {
        morph(to: shape, animated: animated)
        currentShape = shape
    }
    
    private func commonInit() {
        layer.addSublayer(shapeLayer)
    }
    
    private func morph(to key: ShapeKey, animated: Bool) {
        guard let currentKey = currentShape,
              let currentShape = shapes[currentKey],
              let targetShape = shapes[key] else { return }
        shapeLayer.lineWidth = targetShape.lineWidth(for: bounds)
        let currentPath = currentShape.draw(in: bounds).cgPath
        let path = targetShape.draw(in: bounds).cgPath
        if animated {
            let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
            animation.fromValue = currentPath
            animation.toValue = path
            animation.duration = Durations.half
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animation.fillMode = .both
            shapeLayer.add(animation, forKey: animation.keyPath)
        }
        shapeLayer.path = path
    }
}
