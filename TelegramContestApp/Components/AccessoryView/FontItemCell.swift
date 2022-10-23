//
//  FontItemCell.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

final class FontItemCell: UICollectionViewCell, ReusableCell {
    private enum Constants {
        static let fontSize: CGFloat = 18
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
        contentView.layer.cornerRadius = .xs
    }
    
    private func setupBorders(for selected: Bool) {
        if selected {
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        } else {
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        }
    }
    
    func configure(with object: Any) {
        guard let model = object as? FontCustomizationAccessoryViewConfiguration.FontItem else { return }
        fontNameLabel.font = model.font.withSize(Constants.fontSize)
        fontNameLabel.text = model.name
        setupBorders(for: model.isSelected)
    }
    
    
}
