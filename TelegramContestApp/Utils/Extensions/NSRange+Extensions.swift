//
//  NSRange+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 13.10.2022.
//

import Foundation

extension NSRange {
    func contains(range: NSRange) -> Bool {
        return range.location >= location && range.length <= length
    }
}
