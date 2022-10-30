//
//  FontCustomizationAccessoryView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 12.10.2022.
//

import UIKit

protocol FontCustomizationAccessoryViewDelegate: AnyObject {
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem)
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment)
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool)
}

extension FontCustomizationAccessoryViewDelegate {
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem) {}
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment) {}
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool) {}
}

final class FontCustomizationAccessoryView: UIInputView {
    private enum Constants {
        static let height: CGFloat = 48
        static let estimatedWidth: CGFloat = 50
        
        static let fadeWidth: Double = 0.04
        
        static let buttonSide: CGFloat = 30
    }
    
    weak var delegate: FontCustomizationAccessoryViewDelegate?
    
    var outlineConfig: OutlineMode {
        get {
            return outlines[currentOutlineIndex]
        }
    }
    var textAlignment: TextAlignment {
        get {
            return currentTextAlignment
        }
    }
    
    func setBlur(active: Bool) {
        if active {
            effectView.effect = blurEffect
        } else {
            effectView.effect = nil
        }
    }
    
    private var configuration: FontCustomizationAccessoryViewConfiguration? {
        didSet {
            updateConfiguration()
        }
    }
    
    private var currentTextAlignment: TextAlignment = .left
    private var outlines: [OutlineMode] = [
        .none,
        .solid(.white),
        .transparent(.white),
        .text(.red)
    ]
    private var currentOutlineIndex: Int = .zero
    private let fadeLayer: CAGradientLayer = CAGradientLayer()
    
    private lazy var fontCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(
            width: Constants.estimatedWidth,
            height: Constants.height - .xxs
        )
        layout.minimumLineSpacing = .xxs
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.alwaysBounceHorizontal = true
        collection.register(FontItemCell.self)
        collection.delegate = self
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.clipsToBounds = false
        return collection.forAutoLayout()
    }()
    
    private lazy var textAlignmentButton: ShapeMorphingButton<TextAlignment> = {
        let button = ShapeMorphingButton<TextAlignment>(type: .system)
        button.setShapes(
            shapes: Dictionary(uniqueKeysWithValues: TextAlignment.allCases.map { ($0, [TextAlignmentShape(alignment: $0)]) }),
            initial: .left
        )
        
        button.addTarget(self, action: #selector(didTapTextAlignmentButton), for: .touchUpInside)
        
        return button.forAutoLayout()
    }()
    
    private let effectView = UIVisualEffectView(effect: nil).forAutoLayout()
    private let blurEffect = UIBlurEffect(style: .systemMaterialDark)
    
    private lazy var textOutlineButton: ShapeMorphingButton<OutlineMode> = {
        let button = ShapeMorphingButton<OutlineMode>(type: .system)
        button.setShapes(
            shapes: [
                outlines[0]: [
                    OutlineBackgroundShape(
                        outlineMode: outlines[0]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[0]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[0]
                    )
                ],
                outlines[1]: [
                    OutlineBackgroundShape(
                        outlineMode: outlines[1]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[1]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[1]
                    )
                ],
                outlines[2]: [
                    OutlineBackgroundShape(
                        outlineMode: outlines[2]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[2]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[2]
                    )
                ],
                outlines[3]: [
                    OutlineBackgroundShape(
                        outlineMode: outlines[3]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .outline,
                        outlineMode: outlines[3]
                    ),
                    OutlineLetterShape(
                        widthMultiplier: .text,
                        outlineMode: outlines[3]
                    )
                ]
            ],
            initial: outlines[0]
        )
        
        button.addTarget(self, action: #selector(didTapTextOutlineButton), for: .touchUpInside)
        
        return button.forAutoLayout()
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = .s
        
        return stackView.forAutoLayout()
    }()
    
    private let collectionContainer: UIView = UIView().forAutoLayout()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, FontCustomizationAccessoryViewConfiguration.FontItem> = {
        return UICollectionViewDiffableDataSource<Int, FontCustomizationAccessoryViewConfiguration.FontItem>(collectionView: fontCollectionView) { collectionView, indexPath, model in
            return collectionView.dequeueCell(of: FontItemCell.self, for: indexPath, configuredWith: model)
        }
    }()
    
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        guard let superview = self.superview else { return }
//        self.frame = CGRect(x: .zero, y: .zero, width: superview.frame.width, height: Constants.height)
        fadeLayer.frame = collectionContainer.bounds
    }
    
    private func commonInit() {
        autoresizingMask = .flexibleHeight
        addSubviews()
        makeConstraints()
        setupFadingLayer()
    }
    
    private func addSubviews() {
        addSubview(effectView)
        addSubview(buttonsStackView)
        addSubview(collectionContainer)
        collectionContainer.addSubview(fontCollectionView)
        buttonsStackView.addArrangedSubview(textOutlineButton)
        buttonsStackView.addArrangedSubview(textAlignmentButton)
    }
    
    private func makeConstraints() {
        [
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            buttonsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .s),
            buttonsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonsStackView.heightAnchor.constraint(equalToConstant: Constants.buttonSide),
            
            textOutlineButton.widthAnchor.constraint(equalToConstant: Constants.buttonSide),
            textAlignmentButton.widthAnchor.constraint(equalToConstant: Constants.buttonSide),

            collectionContainer.leadingAnchor.constraint(equalTo: textAlignmentButton.trailingAnchor, constant: .xxxs),
            collectionContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionContainer.heightAnchor.constraint(equalToConstant: Constants.height - .xxs),
            collectionContainer.centerYAnchor.constraint(equalTo: buttonsStackView.centerYAnchor),
            
            fontCollectionView.leadingAnchor.constraint(equalTo: collectionContainer.leadingAnchor, constant: .xs),
            fontCollectionView.topAnchor.constraint(equalTo: collectionContainer.topAnchor),
            fontCollectionView.trailingAnchor.constraint(equalTo: collectionContainer.trailingAnchor),
            fontCollectionView.bottomAnchor.constraint(equalTo: collectionContainer.bottomAnchor)
        ].activate()
    }
    
    private func setupFadingLayer() {
        fadeLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.clear.cgColor
        ]
        
        fadeLayer.locations = [
            NSNumber(floatLiteral: .zero),
            NSNumber(floatLiteral: Constants.fadeWidth),
            NSNumber(floatLiteral: 1 - Constants.fadeWidth),
            NSNumber(floatLiteral: 1)
        ]
        
        fadeLayer.startPoint = CGPoint(x: .zero, y: .one.half)
        fadeLayer.endPoint = CGPoint(x: .one, y: .one.half)
        layer.addSublayer(fadeLayer)
        collectionContainer.layer.mask = fadeLayer
    }
    
    private func updateConfiguration() {
        guard let configuration = configuration else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, FontCustomizationAccessoryViewConfiguration.FontItem>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(configuration.fontItems, toSection: .zero)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        currentTextAlignment = configuration.textAlignment
        textAlignmentButton.setShape(configuration.textAlignment, animated: false)
    }
    
    @objc private func didTapTextAlignmentButton() {
        guard let current = textAlignmentButton.currentShape else { return }
        let nextAlignmentRawValue = (current.rawValue + 1) % TextAlignment.allCases.count
        guard let nextAlignment = TextAlignment(rawValue: nextAlignmentRawValue) else { return }
        textAlignmentButton.setShape(nextAlignment, animated: true)
        delegate?.didChangeTextAlignment(from: currentTextAlignment, to: nextAlignment)
    }
    
    @objc private func didTapTextOutlineButton() {
        guard let current = textOutlineButton.currentShape else { return }
        let nextIndex = (currentOutlineIndex + 1) % outlines.count
        let nextOutline = outlines[nextIndex]
        textOutlineButton.setShape(nextOutline, animated: true)
        currentOutlineIndex = nextIndex
        delegate?.didChangeOutlineMode(from: current, to: nextOutline, shouldAnimate: true)
    }
}

extension FontCustomizationAccessoryView: Configurable {
    func configure(with object: Any) {
        guard let configuration = object as? FontCustomizationAccessoryViewConfiguration else { return }
        self.configuration = configuration
    }
}

extension FontCustomizationAccessoryView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let configuration = configuration else { return }
        let selectedItem = configuration.fontItems[indexPath.item]
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        if !selectedItem.isSelected {
            delegate?.didChangeFont(selectedItem)
        }
    }
}
