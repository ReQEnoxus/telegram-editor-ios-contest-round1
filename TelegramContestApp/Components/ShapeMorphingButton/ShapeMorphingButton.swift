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
            
            layer.morph(from: currentShapes[safe: index], to: shape)
        }
    }
}
