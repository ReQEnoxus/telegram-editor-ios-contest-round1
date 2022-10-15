//
//  LabelTextViewLayoutManager.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 15.10.2022.
//

import Foundation
import UIKit

final class LabelTextViewLayoutManager: NSLayoutManager {
    var textContainerOriginOffset: CGSize = .zero
    
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        var customSpacingRanges: [(NSRange, CGFloat)] = []

        textStorage?.enumerateAttribute(.customSpacing, in: characterRange, options: .longestEffectiveRangeNotRequired, using: { (value, subrange, _) in
            guard let value = value as? CGFloat else { return }
            customSpacingRanges.append((subrange, value))
        })
        let remainingRanges = getRemainingRanges(fullRange: glyphsToShow, subtracting: customSpacingRanges.map { $0.0 })
        
        customSpacingRanges.forEach {
            super.drawGlyphs(
                forGlyphRange: $0.0,
                at: CGPoint(
                    x: origin.x + $0.1,
                    y: origin.y
                )
            )
        }
        remainingRanges.forEach {
            super.drawGlyphs(forGlyphRange: $0, at: origin)
        }
    }
    
    private func getRemainingRanges(fullRange: NSRange, subtracting ranges: [NSRange]) -> [NSRange] {
        var mutableSubtractionRanges = ranges
        var result: [NSRange] = []
        var index: Int = .zero
        
        while index < fullRange.length && !mutableSubtractionRanges.isEmpty {
            let nextSubtractingRange = mutableSubtractionRanges[0]
            let length = nextSubtractingRange.location - index
            if length != .zero {
                result.append(NSRange(location: index, length: length))
            }
            index = nextSubtractingRange.location + nextSubtractingRange.length
            mutableSubtractionRanges.removeFirst()
        }
        
        if mutableSubtractionRanges.isEmpty && index < fullRange.length {
            result.append(NSRange(location: index, length: fullRange.length - index))
        }
        
        return result
    }
}
