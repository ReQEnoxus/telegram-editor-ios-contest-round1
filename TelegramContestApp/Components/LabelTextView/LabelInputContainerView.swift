//
//  LabelInputContainerView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 17.10.2022.
//

import Foundation
import UIKit

final class LabelInputContainerView: UIView {
    private enum Constants {
        static let borderRadiusMultipler: CGFloat = 0.08
        static let circleOuterRectSize: CGSize = CGSize(width: 8, height: 8)
    }
    
    enum State {
        case editing
        case `static`
    }
    
    var fontScale: Float {
        get {
            return labelTextView.fontScale
        }
        set {
            labelTextView.fontScale = newValue
        }
    }
    
    var state: State = .editing {
        didSet {
            updateState()
        }
    }
    
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
    private let borderLayer: CAShapeLayer = CAShapeLayer()
    private let leftHandleLayer: CAShapeLayer = CAShapeLayer()
    private let rightHandleLayer: CAShapeLayer = CAShapeLayer()
    private let borderMaskLayer: CAShapeLayer = CAShapeLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        outlineLayer.frame = bounds
        morph(from: currentOutlineMode, to: currentOutlineMode, alignment: TextAlignment.from(nsTextAlignment: labelTextView.textAlignment), animated: false)
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: min(bounds.height * Constants.borderRadiusMultipler, .xs)
        ).cgPath
        leftHandleLayer.position = CGPoint(
            x: borderLayer.frame.minX - Constants.circleOuterRectSize.width.half,
            y: borderLayer.frame.midY - Constants.circleOuterRectSize.height.half
        )
        
        rightHandleLayer.position = CGPoint(
            x: borderLayer.frame.maxX - Constants.circleOuterRectSize.width.half,
            y: borderLayer.frame.midY - Constants.circleOuterRectSize.height.half
        )
        
        let maskPath = UIBezierPath()
        maskPath.append(
            UIBezierPath(
                rect: CGRect(
                    x: -.one.doubled,
                    y: -.one.doubled,
                    width: bounds.width + .xxxs,
                    height: (bounds.height - Constants.circleOuterRectSize.height).half + .one.doubled
                )
            )
        )
        maskPath.move(
            to: CGPoint(
                x: .zero,
                y: bounds.midY + Constants.circleOuterRectSize.height.half
            )
        )
        maskPath.append(
            UIBezierPath(
                rect: CGRect(
                    x: -.one.doubled,
                    y: bounds.midY + Constants.circleOuterRectSize.height.half,
                    width: bounds.width + .xxxs,
                    height: (bounds.height - Constants.circleOuterRectSize.height).half + .one.doubled
                )
            )
        )
        borderMaskLayer.path = maskPath.cgPath
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
        outlineLayer.fillRule = .evenOdd
        setupBorderLayer()
        updateState()
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
    
    private func setupBorderLayer() {
        layer.addSublayer(borderLayer)
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineDashPattern = [12, 8]
        borderLayer.lineCap = .round
        borderLayer.lineWidth = .xxxs.half
        borderLayer.fillColor = UIColor.clear.cgColor
        
        [leftHandleLayer, rightHandleLayer].forEach {
            $0.lineWidth = .xxxs.half
            $0.fillColor = UIColor.clear.cgColor
            $0.strokeColor = UIColor.white.cgColor
            $0.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: Constants.circleOuterRectSize)).cgPath
        }
        
        borderMaskLayer.fillColor = UIColor.white.cgColor
        borderMaskLayer.strokeColor = UIColor.clear.cgColor
        borderLayer.mask = borderMaskLayer
        
        layer.addSublayer(leftHandleLayer)
        layer.addSublayer(rightHandleLayer)
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
    
    private func morph(from currentShape: OutlineMode?, to targetOutline: OutlineMode, customLineInfo: LabelTextView.LineInfo? = nil, alignment: TextAlignment? = nil, animated: Bool) {
        let lineInfo = customLineInfo ?? labelTextView.getLineInfo()
        let shape = OutlineLinesShape(lineInfo: lineInfo, outlineMode: targetOutline, inset: configuration?.outlineInset ?? .zero, alignment: alignment)
        currentOutlineShape = shape
        currentOutlineMode = targetOutline
        outlineLayer.morph(from: currentOutlineShape, to: shape, animated: animated, duration: Durations.half)
    }
    
    private func updateState() {
        switch state {
        case .editing:
            labelTextView.isEditable = true
            borderLayer.isHidden = true
            leftHandleLayer.isHidden = true
            rightHandleLayer.isHidden = true
        case .static:
            labelTextView.isEditable = false
            borderLayer.isHidden = false
            leftHandleLayer.isHidden = false
            rightHandleLayer.isHidden = false
        }
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
        morph(from: outline, to: targetOutline, alignment: TextAlignment.from(nsTextAlignment: labelTextView.textAlignment), animated: true)
    }
    
    func didChangeLineInfo(to new: LabelTextView.LineInfo, alignment: TextAlignment?, shouldAnimate: Bool) {
        morph(from: currentOutlineMode, to: currentOutlineMode, customLineInfo: new, alignment: alignment, animated: shouldAnimate)
    }
}
