//
//  LabelTextViewTextContainer.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 18.10.2022.
//

import UIKit

final class LabelTextViewTextContainer: NSTextContainer {
    var customInsets: [Int: CGFloat] = [:]
    
    override func lineFragmentRect(forProposedRect proposedRect: CGRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<CGRect>?) -> CGRect {
        let rect = super.lineFragmentRect(forProposedRect: proposedRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
        let inset = customInsets[characterIndex] ?? .zero
        let newX: CGFloat
        let newWidth: CGFloat
        if inset >= .zero {
            newX
        }
        let newRect = CGRect(x: rect.origin.x + inset, y: rect.origin.y, width: rect.width - inset, height: rect.height)
        if (characterIndex == .zero) {
            print("!! rect = \(newRect) for \(characterIndex)")
        }
        return newRect
    }
}
