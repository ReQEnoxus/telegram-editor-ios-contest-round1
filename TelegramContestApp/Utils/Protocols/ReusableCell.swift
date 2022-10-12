//
//  ReusableCell.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

protocol ReusableCell: UICollectionViewCell, Configurable {
    static var identifier: String { get }
}

extension ReusableCell {
    static var identifier: String {
        return String(describing: self)
    }
}
