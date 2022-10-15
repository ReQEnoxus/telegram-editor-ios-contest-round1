//
//  TextAlignment.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 15.10.2022.
//

import UIKit

enum TextAlignment: Int, CaseIterable {
    case left = 0
    case right
    case center
    
    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left:
            return .left
        case .right:
            return .right
        case .center:
            return .center
        }
    }
    
    static func from(nsTextAlignment: NSTextAlignment) -> TextAlignment {
        switch nsTextAlignment {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        default:
            return .left
        }
    }
}
