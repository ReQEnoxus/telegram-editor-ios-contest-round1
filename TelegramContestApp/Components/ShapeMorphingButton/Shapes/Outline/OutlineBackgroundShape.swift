//
//  OutlineBackgroundShape.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 16.10.2022.
//

import UIKit

struct OutlineBackgroundShape: Shape {
    private enum Constants {
        static let cornerRadius: CGFloat = 10
    }
    
    let outlineMode: OutlineMode
    
    var strokeColor: CGColor? {
        return nil
    }
    
    var fillColor: CGColor? {
        switch outlineMode {
        case .solid(let color):
            return color.withAlphaComponent(.one).cgColor
        case .transparent(let color, let alphaComponent):
            return color.withAlphaComponent(alphaComponent).cgColor
        case .text, .none:
            return UIColor.clear.cgColor
        }
    }
    
    var lineCap: CAShapeLayerLineCap {
        return .butt
    }
    
    func draw(in bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: Constants.cornerRadius)
        return path
    }
    
    func lineWidth(for bounds: CGRect) -> CGFloat {
        return .zero
    }
}
