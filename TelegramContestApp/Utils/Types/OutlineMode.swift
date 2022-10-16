//
//  OutlineMode.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 16.10.2022.
//

import Foundation
import UIKit

enum OutlineMode: Hashable {
    case solid(UIColor)
    case transparent(UIColor)
    case text(UIColor)
    case none
}
