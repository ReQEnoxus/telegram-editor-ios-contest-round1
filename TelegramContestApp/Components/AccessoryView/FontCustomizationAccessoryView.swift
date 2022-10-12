//
//  FontCustomizationAccessoryView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

final class FontCustomizationAccessoryView: UIView {
    private enum Constants {
        static var height: CGFloat = 64.0
    }
    
    private var configuration: FontCustomizationAccessoryViewConfiguration? {
        didSet {
            updateConfiguration()
        }
    }
    
    private lazy var fontCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(
            width: 50,
            height: Constants.height - .xxsSpace
        )
        layout.minimumInteritemSpacing = .zero
        layout.sectionInset = .zero
        layout.minimumLineSpacing = .xxsSpace
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.alwaysBounceHorizontal = true
        collection.register(FontItemCell.self)
        collection.delegate = self
        return collection.forAutoLayout()
    }()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, FontCustomizationAccessoryViewConfiguration.FontItem> = {
        return UICollectionViewDiffableDataSource<Int, FontCustomizationAccessoryViewConfiguration.FontItem>(collectionView: fontCollectionView) { collectionView, indexPath, model in
            return collectionView.dequeueCell(of: FontItemCell.self, for: indexPath, configuredWith: model)
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = self.superview else { return }
        self.frame = CGRect(x: .zero, y: .zero, width: superview.frame.width, height: Constants.height)
    }
    
    private func commonInit() {
        backgroundColor = .black
        autoresizingMask = .flexibleHeight
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        addSubview(fontCollectionView)
    }
    
    private func makeConstraints() {
        [
            fontCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .xxlSpace),
            fontCollectionView.topAnchor.constraint(equalTo: topAnchor),
            fontCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fontCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    private func updateConfiguration() {
        guard let configuration = configuration else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, FontCustomizationAccessoryViewConfiguration.FontItem>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(configuration.fontItems, toSection: .zero)
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
}

extension FontCustomizationAccessoryView: Configurable {
    func configure(with object: Any) {
        guard let configuration = object as? FontCustomizationAccessoryViewConfiguration else { return }
        self.configuration = configuration
    }
}

extension FontCustomizationAccessoryView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let configuration = configuration else { return }
        var snapshot = dataSource.snapshot()
        let previouslySelectedItem = configuration.fontItems.first(where: { $0.isSelected })
        if let previouslySelectedItem = previouslySelectedItem,
           let previouslySelectedIndex = snapshot.indexOfItem(previouslySelectedItem),
           previouslySelectedIndex != indexPath.row {
            let newItem = FontCustomizationAccessoryViewConfiguration.FontItem(
                font: previouslySelectedItem.font,
                name: previouslySelectedItem.name,
                isSelected: false
            )
            
            snapshot.insertItems([newItem], afterItem: previouslySelectedItem)
            snapshot.deleteItems([previouslySelectedItem])
        }
        
        let selectedItem = configuration.fontItems[indexPath.item]
        if !selectedItem.isSelected {
            let newItem = FontCustomizationAccessoryViewConfiguration.FontItem(
                font: selectedItem.font,
                name: selectedItem.name,
                isSelected: true
            )
            
            snapshot.insertItems([newItem], afterItem: selectedItem)
            snapshot.deleteItems([selectedItem])
            configuration.fontDidChange?(newItem)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
}
