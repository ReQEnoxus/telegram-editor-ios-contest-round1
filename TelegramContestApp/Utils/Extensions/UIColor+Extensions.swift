//
//  UIColor+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 16.10.2022.
//

import UIKit

extension UIColor {
    func isLight(threshold: CGFloat = 0.4) -> Bool? {
        var (red, green, blue, alpha) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000 * alpha
            return brightness > threshold
        }
        else {
            return nil
        }
    }
}
