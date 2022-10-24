//
//  AutoLayout+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

extension UIView {
    func forAutoLayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
}

extension Array where Element == NSLayoutConstraint {
    func activate() {
        NSLayoutConstraint.activate(self)
    }
}

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}

extension CGFloat {
    /// 1
    static let one: CGFloat = 1
    /// 4
    static let xxxs: CGFloat = 4
    /// 8
    static let xxs: CGFloat = 8
    /// 12
    static let xs: CGFloat = 12
    /// 16
    static let s: CGFloat = 16
    /// 24
    static let m: CGFloat = 24
    /// 32
    static let l: CGFloat = 32
    /// 36
    static let xl: CGFloat = 36
    /// 48
    static let xxl: CGFloat = 48
    /// 72
    static let xxxl: CGFloat = 72
    
    var half: CGFloat {
        return self / 2
    }
    
    var doubled: CGFloat {
        return self * 2
    }
}
