//
//  PhotoContainerView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit

final class PhotoContainerView: UIView, ContainerView {
    let imageView: UIImageView = UIImageView().forAutoLayout()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        imageView.contentMode = .scaleAspectFit
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        addSubview(imageView)
    }
    
    private func makeConstraints() {
        [
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    func updateMedia(with media: UIImage?) {
        self.imageView.image = media
    }
}
