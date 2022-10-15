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
        
        func withToggledSelection() -> FontItem {
            return FontItem(
                font: font,
                name: name,
                isSelected: !isSelected
            )
        }
    }
    
    let fontItems: [FontItem]
    let textAlignment: TextAlignment
}
