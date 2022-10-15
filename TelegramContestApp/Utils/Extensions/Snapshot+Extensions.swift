//
//  Snapshot+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 13.10.2022.
//

import Foundation
import UIKit

extension NSDiffableDataSourceSnapshot {
    mutating func replace(item: ItemIdentifierType, with newItem: ItemIdentifierType) {
        guard item != newItem else { return }
        insertItems([newItem], afterItem: item)
        deleteItems([item])
    }
}
