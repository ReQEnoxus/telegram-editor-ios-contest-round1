//
//  OutlineLetterShape.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 16.10.2022.
//

import UIKit

struct OutlineLetterShape: Shape {
    private enum Constants {
        static let verticalSpacingHeightMultiplier: CGFloat = 0.26
        static let baseWidthMultiplier: CGFloat = 0.36
        static let dashTopOffsetMultiplier: CGFloat = 0.36
        static let dashWidthMultiplier: CGFloat = 0.27
    }
    
    enum WidthMultiplier: CGFloat {
        case text = 0.07
        case outline = 0.28
    }
    
    let widthMultiplier: WidthMultiplier
    let outlineMode: OutlineMode
    
    var strokeColor: CGColor? {
        switch outlineMode {
        case .solid(let color):
            return textColor(for: color.withAlphaComponent(.one)).cgColor
        case .transparent(let color, let alphaComponent):
            return textColor(for: color.withAlphaComponent(alphaComponent)).cgColor
        case .text(let color):
            switch widthMultiplier {
            case .text:
                return textColor(for: color).cgColor
            case .outline:
                return color.cgColor
            }
        case .none:
            return UIColor.white.cgColor
        }
    }
    
    var fillColor: CGColor? {
        return nil
    }
    
    var lineCap: CAShapeLayerLineCap {
        return .round
    }
    
    func draw(in bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        let topPoint = CGPoint(
            x: bounds.width.half,
            y: bounds.height * Constants.verticalSpacingHeightMultiplier
        )
        let bottomLeftPoint = CGPoint(
            x: bounds.width * (1 - Constants.baseWidthMultiplier) / 2,
            y: bounds.height * (1 - Constants.verticalSpacingHeightMultiplier)
        )
        let bottomRightPoint = CGPoint(
            x: bounds.width * (1 + Constants.baseWidthMultiplier) / 2,
            y: bottomLeftPoint.y
        )
        let dashLeftPoint = CGPoint(
            x: bounds.width * (1 - Constants.dashWidthMultiplier) / 2,
            y: bounds.height * (Constants.dashTopOffsetMultiplier + Constants.verticalSpacingHeightMultiplier)
        )
        let dashRightPoint = CGPoint(
            x: bounds.width * (1 + Constants.dashWidthMultiplier) / 2,
            y: dashLeftPoint.y
        )
        
        path.move(to: topPoint)
        path.addLine(to: bottomLeftPoint)
        path.move(to: topPoint)
        path.addLine(to: bottomRightPoint)
        path.move(to: dashLeftPoint)
        path.addLine(to: dashRightPoint)
        
        return path
    }
    
    func lineWidth(for bounds: CGRect) -> CGFloat {
        return bounds.height * widthMultiplier.rawValue
    }
    
    private func textColor(for outlineColor: UIColor) -> UIColor {
        if outlineColor.isLight() == true {
            return .black
        } else {
            return .white
        }
    }
}
