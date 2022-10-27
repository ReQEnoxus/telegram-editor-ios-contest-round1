//
//  SegmentedControl.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 27.10.2022.
//

import Foundation
import UIKit

protocol SegmentedControlDelegate: AnyObject {
    func didChangeSelectedIndex(_ index: Int)
}

final class SegmentedControl: UIView {
    private enum Constants {
        static let selectedTransform: CGAffineTransform = CGAffineTransform(
            scaleX: 0.93,
            y: 0.95
        )
        
        static let pointerInset: CGFloat = 2
        
        static let springDamping: CGFloat = 0.85
        static let initialSpringVelocity: CGFloat = 2
    }
    
    struct Model {
        var items: [String]
        var cornerRadius: CGFloat = 16.0
    }
    
    weak var delegate: SegmentedControlDelegate?
    private let contentStackView: UIStackView = UIStackView().forAutoLayout()
    private let selectionView: UIView = UIView().forAutoLayout()
    private var isTracking: Bool = false
    
    private var model: Model? {
        didSet {
            updateModel()
        }
    }
    
    private var currentIndex: Int = .zero
    private var currentVisualIndex: Int = .zero {
        didSet {
            movePointer(to: currentVisualIndex)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !isTracking else { return }
        movePointer(to: currentIndex, animated: false)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateModel() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let model = model else { return }
        model.items.enumerated().forEach {
            let segmentView = SegmentView().forAutoLayout()
            segmentView.text = $1
            segmentView.tag = $0
            contentStackView.addArrangedSubview(segmentView)
        }
        layer.cornerRadius = model.cornerRadius
        selectionView.layer.cornerRadius = model.cornerRadius - Constants.pointerInset.half
        invalidateIntrinsicContentSize()
    }
    
    private func commonInit() {
        setupView()
        addSubviews()
        makeConstraints()
        setupStackView()
        setupSelectionView()
    }
    
    private func setupView() {
        layer.masksToBounds = true
        backgroundColor = Asset.Colors.dark.color
        let pressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPressGesture(gestureRecognizer:))
        )
        pressGestureRecognizer.minimumPressDuration = .zero
        addGestureRecognizer(pressGestureRecognizer)
    }
    
    private func addSubviews() {
        addSubview(selectionView)
        addSubview(contentStackView)
    }
    
    private func makeConstraints() {
        [
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    private func setupStackView() {
        contentStackView.axis = .horizontal
        contentStackView.spacing = .zero
        contentStackView.distribution = .fillEqually
    }
    
    private func setupSelectionView() {
        selectionView.backgroundColor = Asset.Colors.darkSelected.color
    }
    
    private func movePointer(to index: Int, animated: Bool = true) {
        guard let targetFrame = targetFrame(for: index),
              selectionView.frame != targetFrame else { return }
        if animated {
            UIView.animate(
                withDuration: Durations.single,
                delay: .zero,
                usingSpringWithDamping: Constants.springDamping,
                initialSpringVelocity: Constants.initialSpringVelocity,
                options: []
            ) {
                let transform = self.selectionView.transform
                self.selectionView.transform = .identity
                self.selectionView.frame = targetFrame
                self.selectionView.transform = transform
            } completion: { _ in }
        } else {
            selectionView.frame = targetFrame
        }
    }
    
    private func targetFrame(for index: Int) -> CGRect? {
        guard model?.items.indices.contains(index) == true else { return nil }
        let width = contentStackView.frame.width / CGFloat(contentStackView.arrangedSubviews.count)
        return CGRect(
            x: width * CGFloat(index) + Constants.pointerInset,
            y: Constants.pointerInset,
            width: width - Constants.pointerInset.doubled,
            height: contentStackView.frame.height - Constants.pointerInset.doubled
        )
    }
    
    private func applySelectedAnimation(isSelected: Bool) {
        UIView.animate(
            withDuration: Durations.single,
            delay: .zero,
            usingSpringWithDamping: Constants.springDamping,
            initialSpringVelocity: Constants.initialSpringVelocity,
            options: []
        ) {
            self.selectionView.transform = isSelected ? Constants.selectedTransform : .identity
        } completion: { _ in }
    }
    
    private func applyHighlightAnimation(to view: UIView, isHighlighted: Bool) {
        UIView.animate(
            withDuration: Durations.single,
            delay: .zero,
            usingSpringWithDamping: Constants.springDamping,
            initialSpringVelocity: Constants.initialSpringVelocity,
            options: []
        ) {
            view.alpha = isHighlighted ? .one.half : .one
        } completion: { _ in }
    }
    
    @objc private func handleLongPressGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        let position = gestureRecognizer.location(in: contentStackView)
        guard let selectedItem = contentStackView.hitTest(position, with: nil) as? SegmentView else {
            isTracking = false
            applySelectedAnimation(isSelected: false)
            if let highlightedView = contentStackView.arrangedSubviews.first(where: { $0.alpha == .one.half }) {
                applyHighlightAnimation(to: highlightedView, isHighlighted: false)
            }
            if currentVisualIndex != currentIndex {
                currentIndex = currentVisualIndex
                delegate?.didChangeSelectedIndex(currentIndex)
            }
            return
        }
        switch gestureRecognizer.state {
        case .began:
            if selectedItem.tag == currentIndex {
                isTracking = true
                applySelectedAnimation(isSelected: true)
            } else {
                applyHighlightAnimation(to: selectedItem, isHighlighted: true)
            }
        case .changed:
            if isTracking {
                currentVisualIndex = selectedItem.tag
            }
        case .ended:
            isTracking = false
            if selectedItem.tag != currentIndex {
                currentIndex = selectedItem.tag
                currentVisualIndex = selectedItem.tag
                delegate?.didChangeSelectedIndex(currentIndex)
            }
            applySelectedAnimation(isSelected: false)
            if let highlightedView = contentStackView.arrangedSubviews.first(where: { $0.alpha == .one.half }) {
                applyHighlightAnimation(to: highlightedView, isHighlighted: false)
            }
            
        default:
            break
        }
    }
}

extension SegmentedControl: Configurable {
    func configure(with object: Any) {
        guard let model = object as? SegmentedControl.Model else { return }
        self.model = model
    }
}
