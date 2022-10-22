//
//  CustomOutlineLayoutManager.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 22.10.2022.
//

import UIKit

final class CustomOutlineLayoutManager: NSLayoutManager {
    override func showCGGlyphs(_ glyphs: UnsafePointer<CGGlyph>, positions: UnsafePointer<CGPoint>, count glyphCount: Int, font: UIFont, textMatrix: CGAffineTransform, attributes: [NSAttributedString.Key : Any] = [:], in CGContext: CGContext) {
        if let customOutlineColor = attributes[.customOutline] as? UIColor {
            CGContext.saveGState()
            CGContext.setLineWidth(3)
            CGContext.setLineJoin(.round)
            CGContext.setLineCap(.round)
            CGContext.setTextDrawingMode(.stroke)
            CGContext.setStrokeColor(customOutlineColor.cgColor)
            super.showCGGlyphs(glyphs, positions: positions, count: glyphCount, font: font, textMatrix: textMatrix, attributes: attributes, in: CGContext)
            CGContext.restoreGState()
        }
        
        super.showCGGlyphs(glyphs, positions: positions, count: glyphCount, font: font, textMatrix: textMatrix, attributes: attributes, in: CGContext)
    }
}
