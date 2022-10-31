//
//  ColorPickerButton.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 31.10.2022.
//

import Foundation
import UIKit

final class ColorPickerButton: UIButton {
    private enum Constants {
        static let circleViewSize: CGSize = CGSize(width: 19, height: 19)
    }
    private let colorCircle: UIView = UIView().forAutoLayout()
    
    var color: UIColor = .white {
        didSet {
            colorCircle.backgroundColor = color
        }
    }
    
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
        setupInitialState()
    }
    
    private func addSubviews() {
        addSubview(colorCircle)
    }
    
    private func makeConstraints() {
        [
            colorCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            colorCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            colorCircle.heightAnchor.constraint(equalToConstant: Constants.circleViewSize.height),
            colorCircle.widthAnchor.constraint(equalToConstant: Constants.circleViewSize.width)
        ].activate()
    }
    
    private func setupInitialState() {
        setImage(Asset.Icons.picker.image, for: .normal)
        colorCircle.isUserInteractionEnabled = false
        colorCircle.layer.cornerRadius = Constants.circleViewSize.height.half
        colorCircle.backgroundColor = color
    }
}
