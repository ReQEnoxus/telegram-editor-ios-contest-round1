//
//  GradientBackgroundView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 31.10.2022.
//

import Foundation
import QuartzCore
import UIKit

final class GradientBackgroundView: UIView {
    
    private enum Constants {
        static let startLocation: NSNumber = 0
        static let gradientHeight: CGFloat = 16
    }
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialSetup() {
        backgroundColor = .black
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(.zero),
            UIColor.black.cgColor
        ]
        
        layer.mask = gradientLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let endLocationValue = Constants.gradientHeight > bounds.height ? 1 : Constants.gradientHeight / bounds.height
                
        gradientLayer.locations = [Constants.startLocation, NSNumber(value: endLocationValue)]
        gradientLayer.frame = bounds
    }
}
