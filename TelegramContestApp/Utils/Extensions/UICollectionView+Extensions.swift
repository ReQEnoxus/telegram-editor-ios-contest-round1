//
//  UICollectionView+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

extension UICollectionView {
    func register(_ reusableCells: ReusableCell.Type...) {
        reusableCells.forEach {
            register($0.self, forCellWithReuseIdentifier: $0.identifier)
        }
    }
    
    func dequeueCell<CellType: ReusableCell>(of type: CellType.Type, for indexPath: IndexPath, configuredWith object: Any? = nil) -> CellType {
        guard let cell = dequeueReusableCell(withReuseIdentifier: type.identifier, for: indexPath) as? CellType else {
            fatalError("Cell with type \(type.identifier) is not registered")
        }
        if let object = object {
            cell.configure(with: object)
        }
        return cell
    }
}
