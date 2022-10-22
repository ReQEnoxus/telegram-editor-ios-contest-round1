//
//  StringProtocol+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 22.10.2022.
//

import Foundation

extension StringProtocol {

    @inline(__always)
    var trailingNewlinesTrimmed: Self.SubSequence {
        var view = self[...]

        while view.last?.isNewline == true {
            view = view.dropLast()
        }

        return view
    }
}
