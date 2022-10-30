//
//  EditorView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit
import Photos

protocol EditorViewDelegate: AnyObject {
    func didTapExitButton()
    func didTapSaveButton()
    func didChangeEditorMode(_ mode: EditorMode)
}

final class EditorView<Container: ContainerView>: UIView, SegmentedControlDelegate, SliderDelegate, UIGestureRecognizerDelegate {
    var topInset: CGFloat {
        return 0.1 * UIScreen.main.bounds.height
    }
    var bottomInset: CGFloat {
        return 0.13 * UIScreen.main.bounds.height
    }
    var additionalBottomInset: CGFloat = .zero {
        didSet {
            canvasTopInsetConstraint?.constant = topInset - additionalBottomInset
            canvasBottomInsetConstraint?.constant = -bottomInset - additionalBottomInset
        }
    }
    var imageSize: CGSize = .zero {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    // Views
    let containerView: Container = Container().forAutoLayout()
    let canvasView: UIView = UIView().forAutoLayout()
    let keyboardAccessory = FontCustomizationAccessoryView().forAutoLayout()
    var keyboardHeight: CGFloat = .zero {
        didSet {
            accessoryViewOffsetConstraint?.constant = keyboardHeight == .zero ? -.xxs : -(keyboardHeight - (frame.height - saveButton.frame.minY) - (superview?.safeAreaInsets.bottom ?? .zero))
        }
    }
    private let exitButton: UIButton = UIButton(type: .custom).forAutoLayout()
    private let saveButton: UIButton = UIButton(type: .custom).forAutoLayout()
    private let segmentedControl: SegmentedControl = SegmentedControl().forAutoLayout()
    private var currentTextEditingView: TextEditingView?
    private var fontSizeSlider: Slider = Slider().forAutoLayout()
    
    private var fontSliderLeadingOffset: CGFloat = .zero
    private var textGestureRecognizers: [UIView: Set<UIGestureRecognizer>] = [:]
    private var textTransforms: [UIView: CGAffineTransform] = [:]
    
    private var initialFontSize: CGFloat = .zero
    private var currentFontSize: CGFloat = .zero
    
    // Constraints
    
    private var canvasTopInsetConstraint: NSLayoutConstraint?
    private var canvasBottomInsetConstraint: NSLayoutConstraint?
    private var canvasWidthConstraint: NSLayoutConstraint?
    private var canvasHeightConstraint: NSLayoutConstraint?
    private var accessoryViewOffsetConstraint: NSLayoutConstraint?
    
    // Constants
    private let sliderMinValue: Float = 0.33
    private let sliderMaxValue: Float = 1.5
    private let sliderInitialValue: Float = 1
    private let sliderHeight: CGFloat = 240
    private let sliderWidth: CGFloat = 28
    
    weak var delegate: EditorViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSliderFrame()
    }
    
    func updateMedia(with media: Container.Media) {
        containerView.updateMedia(with: media)
    }
    
    func startEditingText(with config: LabelContainerViewConfiguration) -> LabelTextView? {
        guard currentTextEditingView == nil else { return nil }
        let textEditingView = TextEditingView().forAutoLayout()
        textEditingView.labelInputContainer.configure(with: config)
        
        canvasView.addSubview(textEditingView)
        fontSizeSlider.value = sliderInitialValue
        
        textEditingView.alpha = .zero
        [
            textEditingView.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
            textEditingView.topAnchor.constraint(equalTo: canvasView.topAnchor),
            textEditingView.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
            textEditingView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor)
        ].activate()
        layoutIfNeeded()
        initialFontSize = textEditingView.labelInputContainer.labelTextView.font?.pointSize ?? .one
        currentFontSize = initialFontSize
        fontSliderLeadingOffset = -sliderWidth.half + .one.doubled
        UIView.animate(withDuration: Durations.half) {
            textEditingView.alpha = .one
            self.layoutIfNeeded()
        }
        
        textEditingView.labelInputContainer.labelTextView.becomeFirstResponder()
        
        currentTextEditingView = textEditingView
        return textEditingView.labelInputContainer.labelTextView
    }
    
    func discardCurrentlyEditingText() {
        guard let currentTextEditingView = currentTextEditingView else { return }
        endEditing(true)
        fontSliderLeadingOffset = -sliderWidth
        UIView.animate(withDuration: Durations.half) {
            currentTextEditingView.alpha = .zero
            self.updateSliderFrame()
        } completion: { _ in
            currentTextEditingView.removeFromSuperview()
            self.currentTextEditingView = nil
        }
    }
    
    func saveCurrentlyEditingText() {
        guard let currentTextEditingView = currentTextEditingView else { return }
        endEditing(true)
        fontSliderLeadingOffset = -sliderWidth
        currentTextEditingView.labelInputContainer.state = .static
        prepareForRepositionHandling(currentTextEditingView)
        self.currentTextEditingView = nil
        UIView.animate(withDuration: Durations.half) {
            currentTextEditingView.backgroundColor = .clear
            self.updateSliderFrame()
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        canvasTopInsetConstraint?.constant = topInset - additionalBottomInset
        canvasBottomInsetConstraint?.constant = -bottomInset - additionalBottomInset
        canvasWidthConstraint?.constant = imageSize.width
        canvasHeightConstraint?.constant = imageSize.height
    }
    
    private func commonInit() {
        backgroundColor = .black
        canvasView.clipsToBounds = true
        addSubviews()
        makeConstraints()
        setupExitButton()
        setupSaveButton()
        setupSegmentedControl()
        setupSlider()
    }
    
    private func addSubviews() {
        addSubview(containerView)
        addSubview(canvasView)
        addSubview(exitButton)
        addSubview(saveButton)
        addSubview(segmentedControl)
        addSubview(fontSizeSlider)
        addSubview(keyboardAccessory)
    }
    
    private func makeConstraints() {
        canvasTopInsetConstraint = containerView.topAnchor.constraint(equalTo: topAnchor, constant: topInset)
        canvasBottomInsetConstraint = containerView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -bottomInset)
        canvasHeightConstraint = canvasView.heightAnchor.constraint(equalToConstant: .zero)
        canvasWidthConstraint = canvasView.widthAnchor.constraint(equalToConstant: .zero)
        accessoryViewOffsetConstraint = keyboardAccessory.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -.s)
        [
            canvasTopInsetConstraint,
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasBottomInsetConstraint,
            
            canvasView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            canvasView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            canvasHeightConstraint,
            canvasWidthConstraint,
            
            keyboardAccessory.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: .s),
            keyboardAccessory.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            keyboardAccessory.heightAnchor.constraint(equalToConstant: .xxl),
            accessoryViewOffsetConstraint,
            
            exitButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: .s),
            exitButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.m),
            exitButton.widthAnchor.constraint(equalToConstant: .l),
            exitButton.heightAnchor.constraint(equalToConstant: .l),
            
            saveButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -.s),
            saveButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.m),
            saveButton.widthAnchor.constraint(equalToConstant: .l),
            saveButton.heightAnchor.constraint(equalToConstant: .l),
            
            segmentedControl.leadingAnchor.constraint(equalTo: exitButton.trailingAnchor, constant: .s),
            segmentedControl.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -.s),
            segmentedControl.centerYAnchor.constraint(equalTo: exitButton.centerYAnchor)
        ].compactMap { $0 }.activate()
    }
    
    private func setupExitButton() {
        exitButton.addTarget(self, action: #selector(handleExitTap), for: .touchUpInside)
        exitButton.setImage(Asset.Icons.cancel.image, for: .normal)
        exitButton.tintColor = .white
        exitButton.adjustsImageWhenHighlighted = false
    }
    
    private func setupSaveButton() {
        saveButton.addTarget(self, action: #selector(handleSaveTap), for: .touchUpInside)
        saveButton.setImage(Asset.Icons.save.image, for: .normal)
        saveButton.tintColor = .white
        saveButton.adjustsImageWhenHighlighted = false
    }
    
    private func setupSegmentedControl() {
        segmentedControl.configure(
            with: SegmentedControl.Model(
                items: [
                    L10n.Screens.Editor.Modes.draw,
                    L10n.Screens.Editor.Modes.text
                ],
                cornerRadius: .s
            )
        )
        segmentedControl.delegate = self
    }
    
    private func setupSlider() {
        fontSizeSlider.minimumValue = sliderMinValue
        fontSizeSlider.maximumValue = sliderMaxValue
        fontSliderLeadingOffset = -sliderWidth
        
        fontSizeSlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        
        fontSizeSlider.delegate = self
    }
    
    private func updateSliderFrame() {
        fontSizeSlider.frame = CGRect(
            x: containerView.frame.minX + fontSliderLeadingOffset,
            y: containerView.frame.minY + (containerView.frame.height - sliderHeight).half,
            width: sliderWidth,
            height: sliderHeight
        )
    }
    
    private func prepareForRepositionHandling(_ editingView: UIView) {
        textTransforms[editingView] = editingView.transform
        textGestureRecognizers[editingView] = Set<UIGestureRecognizer>(minimumCapacity: 3)
        
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleDoubleFingerGesture(gestureRecognizer:)))
        rotationRecognizer.delegate = self
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handleDoubleFingerGesture(gestureRecognizer:)))
        pinchRecognizer.delegate = self
        
        let doublePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDoubleFingerGesture(gestureRecognizer:)))
        doublePanRecognizer.minimumNumberOfTouches = 2
        doublePanRecognizer.maximumNumberOfTouches = 2
        doublePanRecognizer.delegate = self
        
        let singlePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSingleFingerGesture(gestureRecognizer:)))
        singlePanRecognizer.minimumNumberOfTouches = 1
        singlePanRecognizer.maximumNumberOfTouches = 1
        
        [rotationRecognizer, pinchRecognizer, doublePanRecognizer, singlePanRecognizer].forEach {
            editingView.addGestureRecognizer($0)
        }
    }
    
    private func adjustTransform(with recognizer: UIGestureRecognizer, initial: CGAffineTransform) -> CGAffineTransform {
        switch recognizer {
        case let rotationRecognizer as UIRotationGestureRecognizer:
            return initial.rotated(by: rotationRecognizer.rotation)
        case let pinchRecognizer as UIPinchGestureRecognizer:
            return initial.scaledBy(x: pinchRecognizer.scale, y: pinchRecognizer.scale)
        case let panRecognizer as UIPanGestureRecognizer:
            return initial.translatedBy(
                x: panRecognizer.translation(in: panRecognizer.view).x,
                y: panRecognizer.translation(in: panRecognizer.view).y
            )
        default:
            return initial
        }
    }
    
    func didChangeSelectedIndex(_ index: Int) {
        guard let currentMode = EditorMode(rawValue: index) else { return }
        delegate?.didChangeEditorMode(currentMode)
    }
    
    func valueChanged(to newValue: Float) {
        guard let editingView = currentTextEditingView else { return }
        editingView.labelInputContainer.fontScale = newValue
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let other = otherGestureRecognizer as? UIPanGestureRecognizer,
           other.minimumNumberOfTouches == 1 {
            return false
        } else {
            return true
        }
    }
    
    @objc private func handleExitTap() {
        delegate?.didTapExitButton()
    }
    
    @objc private func handleSaveTap() {
        delegate?.didTapSaveButton()
    }
    
    @objc private func handleSingleFingerGesture(gestureRecognizer: UIPanGestureRecognizer) {
        guard let editingView = gestureRecognizer.view as? TextEditingView else { return }
        let touchType = editingView.touchType(for: gestureRecognizer.location(in: editingView))
        
        switch touchType {
        case .inside, .leftHandle, .rightHandle:
            // TODO: rotation and resize on handles if a few spare hours left
            handleInsidePan(gestureRecognizer: gestureRecognizer, view: editingView)
        case .outside:
            if gestureRecognizer.state == .changed {
                handleInsidePan(gestureRecognizer: gestureRecognizer, view: editingView)
            } else {
                // fail gesture
                gestureRecognizer.isEnabled = false
                gestureRecognizer.isEnabled = true
            }
        }
    }
    
    private func handleInsidePan(gestureRecognizer: UIPanGestureRecognizer, view: TextEditingView) {
        guard let initialTransform = textTransforms[view] else { return }
        switch gestureRecognizer.state {
        case .changed:
            let adjustedTransform = initialTransform.translatedBy(
                x: gestureRecognizer.translation(in: view).x,
                y: gestureRecognizer.translation(in: view).y
            )
            view.transform = adjustedTransform
        case .ended:
            textTransforms[view] = view.transform
        default:
            break
        }
    }
    
    @objc private func handleDoubleFingerGesture(gestureRecognizer: UIGestureRecognizer) {
        guard let view = gestureRecognizer.view,
              textGestureRecognizers[view] != nil else { return }
        switch gestureRecognizer.state {
        case .began:
            textGestureRecognizers[view]?.insert(gestureRecognizer)
        case .changed:
            guard var transform = textTransforms[view] else { return }
            textGestureRecognizers[view]?.forEach {
                transform = adjustTransform(with: $0, initial: transform)
            }
            view.transform = transform
        case .ended:
            textGestureRecognizers[view]?.remove(gestureRecognizer)
            if textGestureRecognizers[view]?.isEmpty == true {
                textTransforms[view] = view.transform
            }
        default:
            break
        }
    }
}

extension EditorView: ExportableView {
    func prepare() {
        canvasView.subviews.forEach {
            if let exportableView = $0 as? ExportableView {
                exportableView.prepare()
                exportableView.contentScaleFactor = UIScreen.main.scale
            } else {
                $0.isHidden = true
            }
        
        }
    }
}
