//
//  NSMutableAttributedString+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 22.10.2022.
//

import Foundation

extension NSAttributedString {

    var withTrimmedWhitespaces: NSAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.inverted
        let startRange = string.rangeOfCharacter(from: invertedSet)
        let endRange = string.rangeOfCharacter(from: invertedSet, options: .backwards)
        let startLocation = string.startIndex
        let endLocation = endRange?.lowerBound ?? String(string.dropLast()).endIndex

        let trimmedRange = startLocation...endLocation
        return attributedSubstring(from: NSRange(trimmedRange, in: string))
    }
}
