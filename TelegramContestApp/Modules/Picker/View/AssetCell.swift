//
//  AssetCell.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import UIKit
import Photos

protocol AssetCellDelegate: AnyObject {
    func didConfigure(with model: AssetCell.Model, size: CGSize, onLoad: Consumer<UIImage?>?)
}

final class AssetCell: UICollectionViewCell {
    struct Model: Hashable {
        let asset: PHAsset
    }
    
    weak var delegate: AssetCellDelegate?
    private let imageView: UIImageView = UIImageView().forAutoLayout()
    private let durationLabel: UILabel = UILabel().forAutoLayout()
    private var heightConstraint: NSLayoutConstraint?
    
    private var model: Model?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        backgroundColor = .systemGray2
        clipsToBounds = true
        addSubviews()
        makeConstraints()
        setupImageView()
        setupDurationLabel()
    }
    
    private func addSubviews() {
        contentView.addSubview(imageView)
        contentView.addSubview(durationLabel)
    }
    
    private func makeConstraints() {
        heightConstraint = imageView.heightAnchor.constraint(equalToConstant: .zero).withPriority(UILayoutPriority.init(rawValue: 999))
        [
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            heightConstraint,
            
            durationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].compactMap { $0 }.activate()
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
    }
    
    private func setupDurationLabel() {
        durationLabel.textColor = .white
        durationLabel.textAlignment = .right
        durationLabel.font = .systemFont(ofSize: .xs, weight: .regular)
    }
}

extension AssetCell: ReusableCell {
    func configure(with object: Any) {
        guard let model = object as? AssetCell.Model else { return }
        
        self.model = model
        if model.asset.mediaType == .video {
            durationLabel.text = "\(model.asset.duration)"
        }
        
        let ratio = CGFloat(model.asset.pixelHeight) / CGFloat(model.asset.pixelWidth)
        let targetSize = CGSize(
            width: bounds.width * UIScreen.main.scale,
            height: bounds.width * UIScreen.main.scale * ratio
        )
        heightConstraint?.constant = targetSize.height
        
        delegate?.didConfigure(with: model, size: targetSize, onLoad: { image in
            guard self.model?.asset.localIdentifier == model.asset.localIdentifier else { return }
            self.imageView.image = image
        })
    }
}
