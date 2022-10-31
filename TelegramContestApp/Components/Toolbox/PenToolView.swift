//
//  PenToolView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 30.10.2022.
//

import Foundation
import UIKit

final class PenToolView: UIView {
    private enum Constants {
        static let maskWidth: CGFloat = 10
        static let maskHeight: CGFloat = 20
        static let maskTopOffset: CGFloat = 8
        static let widthViewTopOffset: CGFloat = 82
        
        static let widthViewWidthMultiplier: CGFloat = 0.85
    }
    var width: CGFloat = .xxxs {
        didSet {
            updateWidth()
        }
    }
    
    var color: UIColor = .black {
        didSet {
            updateColor()
        }
    }
    
    private let maskedTipImageView: UIImageView = UIImageView().forAutoLayout()
    private let penImageView: UIImageView = UIImageView().forAutoLayout()
    private let tipMaskLayer: CAShapeLayer = CAShapeLayer()
    private let widthView: UIView = UIView().forAutoLayout()
    private var widthViewHeightConstraint: NSLayoutConstraint?
    
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
        tipMaskLayer.frame = bounds
        tipMaskLayer.fillColor = UIColor.white.cgColor
        tipMaskLayer.path = UIBezierPath(
            roundedRect: CGRect(
                x: bounds.midX - Constants.maskWidth.half,
                y: Constants.maskTopOffset,
                width: Constants.maskWidth,
                height: Constants.maskHeight
            ),
            cornerRadius: .xxxs.half
        ).cgPath
    }
    
    private func commonInit() {
        addSubviews()
        setupImage()
        makeConstraints()
        updateWidth()
        updateColor()
    }
    
    private func addSubviews() {
        addSubview(penImageView)
        addSubview(maskedTipImageView)
        addSubview(widthView)
    }
    
    private func makeConstraints() {
        widthViewHeightConstraint = widthView.heightAnchor.constraint(equalToConstant: width)
        ([penImageView, maskedTipImageView].flatMap {
            [
                $0.leadingAnchor.constraint(equalTo: leadingAnchor),
                $0.topAnchor.constraint(equalTo: topAnchor),
                $0.trailingAnchor.constraint(equalTo: trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        } + [
            widthView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.widthViewTopOffset),
            widthView.centerXAnchor.constraint(equalTo: centerXAnchor),
            widthView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Constants.widthViewWidthMultiplier),
            widthViewHeightConstraint
        ]).compactMap { $0 }.activate()
    }
    
    private func setupImage() {
        penImageView.contentMode = .scaleToFill
        maskedTipImageView.contentMode = .scaleToFill
        penImageView.image = Asset.Icons.pen.image.withRenderingMode(.alwaysOriginal)
        maskedTipImageView.image = Asset.Icons.pen.image.withRenderingMode(.alwaysTemplate)
        maskedTipImageView.layer.mask = tipMaskLayer
        widthView.layer.cornerRadius = .one.doubled
    }
    
    private func updateWidth() {
        widthViewHeightConstraint?.constant = width.half
    }
    
    private func updateColor() {
        maskedTipImageView.tintColor = color
        widthView.backgroundColor = color
    }
}
