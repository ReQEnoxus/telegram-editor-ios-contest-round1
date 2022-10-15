//
//  TextAlignmentShape.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 15.10.2022.
//

import UIKit

struct TextAlignmentShape: Shape {
    private enum Constants {
        static let lineHeightMultiplier: CGFloat = 0.05
        static let verticalPaddingMultiplier: CGFloat = 0.21
        static let longLineWidthMultipler: CGFloat = 0.7
        static let shortLineWidthMultiplier: CGFloat = 0.45
        static let interItemSpacingMultiplier: CGFloat = 0.12
    }
    
    let alignment: TextAlignment
    
    func lineWidth(for bounds: CGRect) -> CGFloat {
        return Constants.lineHeightMultiplier * bounds.height
    }
    
    func draw(in bounds: CGRect) -> UIBezierPath {
        switch alignment {
        case .left:
            return drawLeft(in: bounds)
        case .center:
            return drawCenter(in: bounds)
        case .right:
            return drawRight(in: bounds)
        }
    }
    
    private func drawLeft(in bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        addLine(
            index: .zero,
            bounds: bounds,
            length: bounds.width * Constants.longLineWidthMultipler,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        addLine(
            index: 1,
            bounds: bounds,
            length: bounds.width * Constants.shortLineWidthMultiplier,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        addLine(
            index: 2,
            bounds: bounds,
            length: bounds.width * Constants.longLineWidthMultipler,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        
        addLine(
            index: 3,
            bounds: bounds,
            length: bounds.width * Constants.shortLineWidthMultiplier,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        
        return path
    }
    
    private func drawCenter(in bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        addLine(
            index: .zero,
            bounds: bounds,
            length: bounds.width * Constants.longLineWidthMultipler,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        addLine(
            index: 1,
            bounds: bounds,
            length: bounds.width * Constants.shortLineWidthMultiplier,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2 + bounds.width * (Constants.longLineWidthMultipler - Constants.shortLineWidthMultiplier) / 2,
            to: path
        )
        addLine(
            index: 2,
            bounds: bounds,
            length: bounds.width * Constants.longLineWidthMultipler,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        
        addLine(
            index: 3,
            bounds: bounds,
            length: bounds.width * Constants.shortLineWidthMultiplier,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2 + bounds.width * (Constants.longLineWidthMultipler - Constants.shortLineWidthMultiplier) / 2,
            to: path
        )
        
        return path
    }
    
    private func drawRight(in bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        addLine(
            index: .zero,
            bounds: bounds,
            length: bounds.width * Constants.longLineWidthMultipler,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        addLine(
            index: 1,
            bounds: bounds,
            length: bounds.width * Constants.shortLineWidthMultiplier,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2 + bounds.width * (Constants.longLineWidthMultipler - Constants.shortLineWidthMultiplier),
            to: path
        )
        addLine(
            index: 2,
            bounds: bounds,
            length: bounds.width * Constants.longLineWidthMultipler,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2,
            to: path
        )
        
        addLine(
            index: 3,
            bounds: bounds,
            length: bounds.width * Constants.shortLineWidthMultiplier,
            leftOffset: bounds.width * (1 - Constants.longLineWidthMultipler) / 2 + bounds.width * (Constants.longLineWidthMultipler - Constants.shortLineWidthMultiplier),
            to: path
        )
        
        return path
    }
    
    private func addLine(
        index: Int,
        bounds: CGRect,
        length: CGFloat,
        leftOffset: CGFloat,
        to path: UIBezierPath
    ) {
        let indexBasedOffset = CGFloat(index) * (bounds.height * Constants.interItemSpacingMultiplier + lineWidth(for: bounds))
        let lineStartPoint = CGPoint(
            x: leftOffset,
            y: bounds.height * Constants.verticalPaddingMultiplier + indexBasedOffset + lineWidth(for: bounds) / 2
        )
        let lineEndPoint = CGPoint(
            x: lineStartPoint.x + length,
            y: lineStartPoint.y
        )
        path.move(to: lineStartPoint)
        path.addLine(to: lineEndPoint)
    }
}
