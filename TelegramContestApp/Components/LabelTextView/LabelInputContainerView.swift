//
//  LabelInputContainerView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 17.10.2022.
//

import Foundation
import UIKit

final class LabelInputContainerView: UIView {
    
    private let outlineLayer: CAShapeLayer = CAShapeLayer()
    let labelTextView: LabelTextView = LabelTextView().forAutoLayout()
    private var currentOutlineShape: Shape?
    private var currentOutlineMode: OutlineMode = .none
    private var configuration: LabelContainerViewConfiguration? {
        didSet {
            updateConfiguration()
        }
    }
    private var currentConstraints: [NSLayoutConstraint] = []
    
    override func layoutSubviews() {
        super.layoutSubviews()
        outlineLayer.frame = bounds
        morph(from: currentOutlineMode, to: currentOutlineMode, animated: false)
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
        layer.addSublayer(outlineLayer)
        addSubviews()
        makeConstraints()
        labelTextView.outlineDelegate = self
    }
    
    private func addSubviews() {
        addSubview(labelTextView)
    }
    
    private func makeConstraints() {
        currentConstraints = [
            labelTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelTextView.topAnchor.constraint(equalTo: topAnchor),
            labelTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelTextView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        currentConstraints.activate()
    }
    
    private func updateConfiguration() {
        guard let configuration = configuration else { return }
        labelTextView.configure(with: configuration.labelConfiguration)
        
        currentConstraints.forEach { constraint in
            switch constraint.secondItem {
            case let xAnchor as NSLayoutXAxisAnchor:
                switch xAnchor {
                case leadingAnchor:
                    constraint.constant = configuration.outlineInset
                case trailingAnchor:
                    constraint.constant = -configuration.outlineInset
                default:
                    break
                }
            case let yAnchor as NSLayoutYAxisAnchor:
                switch yAnchor {
                case topAnchor:
                    constraint.constant = configuration.outlineInset
                case bottomAnchor:
                    constraint.constant = -configuration.outlineInset
                default:
                    break
                }
            default:
                break
            }
        }
        setNeedsLayout()
    }
    
    private func morph(from currentShape: OutlineMode?, to targetOutline: OutlineMode, customLineInfo: LabelTextView.LineInfo? = nil, animated: Bool) {
        let lineInfo = customLineInfo ?? labelTextView.getLineInfo()
        let shape = OutlineLinesShape(lineInfo: lineInfo, outlineMode: targetOutline)
        currentOutlineShape = shape
        currentOutlineMode = targetOutline
        outlineLayer.morph(from: currentOutlineShape, to: shape, animated: animated)
    }
}

extension LabelInputContainerView: Configurable {
    func configure(with object: Any) {
        guard let configuration = object as? LabelContainerViewConfiguration else { return }
        self.configuration = configuration
    }
}

extension LabelInputContainerView: OutlineLabelDelegate {
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode) {
        morph(from: outline, to: targetOutline, animated: true)
    }
    
    func didChangeLineInfo(to new: LabelTextView.LineInfo) {
        morph(from: currentOutlineMode, to: currentOutlineMode, customLineInfo: new, animated: true)
    }
}
