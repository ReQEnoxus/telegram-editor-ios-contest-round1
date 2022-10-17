//
//  OutlineLinesShape.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 17.10.2022.
//

import UIKit

struct OutlineLinesShape: Shape {
    let lineInfo: LabelTextView.LineInfo
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
        let path = UIBezierPath()
        lineInfo.lines.forEach {
            path.move(to: $0.rect.origin)
            path.append(UIBezierPath(rect: $0.rect))
        }
        
        return path
    }
    
    func lineWidth(for bounds: CGRect) -> CGFloat {
        return .zero
    }
}
