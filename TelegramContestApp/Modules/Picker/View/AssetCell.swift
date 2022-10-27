//
//  AssetCell.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import UIKit
import Photos

final class AssetCell: UICollectionViewCell {
    private enum Constants {
        static let scaleMultiplier: CGFloat = 1
    }
    
    struct Model: Hashable {
        let duration: String?
        let pixelHeight: Int
        let pixelWidth: Int
    }
    
    var assetId: String?
    var cancelId: PHImageRequestID?
    let imageView: UIImageView = UIImageView().forAutoLayout()
    private let durationLabel: UILabel = UILabel().forAutoLayout()
    private var heightConstraint: NSLayoutConstraint?
    
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
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
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
        
        durationLabel.text = model.duration
        
        let ratio = CGFloat(model.pixelHeight) / CGFloat(model.pixelWidth)
        let targetSize = CGSize(
            width: bounds.width * UIScreen.main.scale * Constants.scaleMultiplier,
            height: bounds.width * UIScreen.main.scale * Constants.scaleMultiplier * ratio
        )
        heightConstraint?.constant = targetSize.height
    }
    
    func updateImage(with image: UIImage?) {
        UIView.transition(
            with: self.imageView,
            duration: Durations.half,
            options: [.curveEaseIn, .transitionCrossDissolve]
        ) {
            self.imageView.image = image
        } completion: { _ in }
    }
}
