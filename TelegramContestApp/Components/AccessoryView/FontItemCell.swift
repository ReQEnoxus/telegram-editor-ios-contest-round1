//
//  FontItemCell.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

final class FontItemCell: UICollectionViewCell, ReusableCell {
    private enum Constants {
        static let fontSize: CGFloat = 13
        static let cornerRadius: CGFloat = 9
        static let borderWidth: CGFloat = 0.33
        static let selectedBorderWidth: CGFloat = 0.67
        static let unselectedBorderAlpha: CGFloat = 0.33
    }
    
    private let fontNameLabel: UILabel = UILabel().forAutoLayout()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        addSubviews()
        makeConstraints()
        setupLabel()
        setupContentBorders()
    }
    
    private func addSubviews() {
        contentView.addSubview(fontNameLabel)
    }
    
    private func makeConstraints() {
        [
            fontNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .s),
            fontNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.s),
            fontNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .xxs),
            fontNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.xxs),
        ].activate()
    }
    
    private func setupLabel() {
        fontNameLabel.textColor = .white
    }
    
    private func setupContentBorders() {
        contentView.layer.borderWidth = .one
        contentView.layer.cornerRadius = Constants.cornerRadius
    }
    
    private func setupBorders(for selected: Bool) {
        if selected {
            contentView.layer.borderColor = UIColor.white.cgColor
            contentView.layer.borderWidth = Constants.selectedBorderWidth
        } else {
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(Constants.unselectedBorderAlpha).cgColor
            contentView.layer.borderWidth = Constants.borderWidth
        }
    }
    
    func configure(with object: Any) {
        guard let model = object as? FontCustomizationAccessoryViewConfiguration.FontItem else { return }
        fontNameLabel.font = model.font.withSize(Constants.fontSize)
        fontNameLabel.text = model.name
        setupBorders(for: model.isSelected)
    }
    
    
}
