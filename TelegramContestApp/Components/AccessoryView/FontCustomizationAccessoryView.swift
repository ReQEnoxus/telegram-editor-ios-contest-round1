//
//  FontCustomizationAccessoryView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

protocol FontCustomizationAccessoryViewDelegate: AnyObject {
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem)
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment)
}

extension FontCustomizationAccessoryViewDelegate {
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem) {}
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment) {}
}

final class FontCustomizationAccessoryView: UIInputView {
    private enum Constants {
        static let height: CGFloat = 64.0
        static let estimatedWidth: CGFloat = 50
        
        static let buttonSide: CGFloat = 36
    }
    
    weak var delegate: FontCustomizationAccessoryViewDelegate?
    
    private var configuration: FontCustomizationAccessoryViewConfiguration? {
        didSet {
            updateConfiguration()
        }
    }
    
    private var currentTextAlignment: TextAlignment = .left
    
    private lazy var fontCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(
            width: Constants.estimatedWidth,
            height: Constants.height - .xxsSpace
        )
        layout.minimumInteritemSpacing = .zero
        layout.sectionInset = .zero
        layout.minimumLineSpacing = .xxsSpace
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.alwaysBounceHorizontal = true
        collection.register(FontItemCell.self)
        collection.delegate = self
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        return collection.forAutoLayout()
    }()
    
    private lazy var textAlignmentButton: ShapeMorphingButton<TextAlignment> = {
        let button = ShapeMorphingButton<TextAlignment>(type: .system)
        button.setShapes(
            shapes: [
                .left: TextAlignmentShape(alignment: .left),
                .center: TextAlignmentShape(alignment: .center),
                .right: TextAlignmentShape(alignment: .right)
            ],
            initial: .left
        )
        
        button.addTarget(self, action: #selector(didTapTextAlignmentButton), for: .touchUpInside)
        
        return button.forAutoLayout()
    }()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, FontCustomizationAccessoryViewConfiguration.FontItem> = {
        return UICollectionViewDiffableDataSource<Int, FontCustomizationAccessoryViewConfiguration.FontItem>(collectionView: fontCollectionView) { collectionView, indexPath, model in
            return collectionView.dequeueCell(of: FontItemCell.self, for: indexPath, configuredWith: model)
        }
    }()
    
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
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
        autoresizingMask = .flexibleHeight
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        addSubview(fontCollectionView)
        addSubview(textAlignmentButton)
    }
    
    private func makeConstraints() {
        [
            textAlignmentButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .sSpace),
            textAlignmentButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            textAlignmentButton.widthAnchor.constraint(equalToConstant: Constants.buttonSide),
            textAlignmentButton.heightAnchor.constraint(equalToConstant: Constants.buttonSide),

            fontCollectionView.leadingAnchor.constraint(equalTo: textAlignmentButton.trailingAnchor, constant: .sSpace),
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
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        currentTextAlignment = configuration.textAlignment
        textAlignmentButton.setShape(configuration.textAlignment, animated: false)
    }
    
    @objc private func didTapTextAlignmentButton() {
        guard let current = textAlignmentButton.currentShape else { return }
        let nextAlignmentRawValue = (current.rawValue + 1) % TextAlignment.allCases.count
        guard let nextAlignment = TextAlignment(rawValue: nextAlignmentRawValue) else { return }
        textAlignmentButton.setShape(nextAlignment, animated: true)
        delegate?.didChangeTextAlignment(from: currentTextAlignment, to: nextAlignment)
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
        let selectedItem = configuration.fontItems[indexPath.item]
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        if !selectedItem.isSelected {
            delegate?.didChangeFont(selectedItem)
        }
    }
}
