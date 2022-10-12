//
//  FontCustomizationAccessoryViewConfiguration.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

struct FontCustomizationAccessoryViewConfiguration: Hashable {
    struct FontItem: Hashable {
        let font: UIFont
        let name: String
        let isSelected: Bool
    }
    
    let fontItems: [FontItem]
    let fontDidChange: Consumer<FontItem>?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fontItems)
    }
    
    static func == (lhs: FontCustomizationAccessoryViewConfiguration, rhs: FontCustomizationAccessoryViewConfiguration) -> Bool {
        return lhs.fontItems == rhs.fontItems
    }
}
