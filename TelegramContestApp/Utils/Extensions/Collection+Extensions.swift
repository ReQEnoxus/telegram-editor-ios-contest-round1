//
//  Collection+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 16.10.2022.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
