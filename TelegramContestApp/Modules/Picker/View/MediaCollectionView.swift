//
//  MediaCollectionView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import Foundation
import UIKit

final class MediaCollectionView: UIView {
    private enum Constants {
        static let itemSpacing: CGFloat = 1
        static let estimatedSingleItemHeight: CGFloat = 80
    }
    
    enum ZoomLevel: Int {
        case single = 1
        case three = 3
        case five = 5
        case twelve = 12
    }
    
    lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout(for: .three))
        return collection.forAutoLayout()
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        addSubviews()
        makeConstraints()
        setupCollectionView()
    }
    
    private func addSubviews() {
        addSubview(collectionView)
    }
    
    private func makeConstraints() {
        [
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    private func setupCollectionView() {
        collectionView.register(AssetCell.self)
        collectionView.backgroundColor = .black
    }
    
    private func collectionLayout(for zoomLevel: ZoomLevel) -> UICollectionViewLayout {
        switch zoomLevel {
        case .single:
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.fractionalWidth(.one),
                heightDimension: NSCollectionLayoutDimension.estimated(Constants.estimatedSingleItemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)

            let section = NSCollectionLayoutSection(group: group)

            return UICollectionViewCompositionalLayout(section: section)
        default:
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(.one),
                heightDimension: .fractionalWidth(.one / CGFloat(zoomLevel.rawValue))
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(.one),
                    heightDimension: .estimated(Constants.estimatedSingleItemHeight)
                ),
                subitem: item,
                count: zoomLevel.rawValue
            )
            group.interItemSpacing = .fixed(.one)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = .one
            return UICollectionViewCompositionalLayout(section: section)
        }
    }
}
