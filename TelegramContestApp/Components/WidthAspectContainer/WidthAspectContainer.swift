//
//  WidthAspectContainer.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit

final class WidthAspectContainer: UIView {
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            setNeedsLayout()
        }
    }
    
    private let imageView = UIImageView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = image else {
            imageView.frame = bounds
            return
        }
//        let factor: CGFloat
//        let widthFactor = bounds.width / image.size.width
//        let targetHeight = image.size.height * factor
//        if targetHeight < bounds.height
//        imageView.frame = CGRect(
//            x: .zero,
//            y: (bounds.height - targetHeight).half,
//            width: bounds.width,
//            height: targetHeight
//        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        addSubviews()
        clipsToBounds = true
        imageView.contentMode = .scaleToFill
    }
    
    private func addSubviews() {
        addSubview(imageView)
    }
}
