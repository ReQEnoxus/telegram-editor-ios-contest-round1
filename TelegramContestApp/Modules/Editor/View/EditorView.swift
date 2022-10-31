//
//  EditorView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit
import Photos
import PencilKit

extension PKCanvasView: ExportableView {
    func prepare() {
        
    }
}

protocol EditorViewDelegate: AnyObject {
    func didTapExitButton()
    func didTapSaveButton()
    func didChangeEditorMode(_ mode: EditorMode)
    func didTapColorPickerButton(_ button: ColorPickerButton)
    func requestStartEditing()
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
    let drawingCanvas: PKCanvasView = PKCanvasView().forAutoLayout()
    private let exitButton: LottieCloseButton = LottieCloseButton().forAutoLayout()
    let saveButton: UIButton = UIButton(type: .custom).forAutoLayout()
    private let morphControl: MorphingSlider = MorphingSlider().forAutoLayout()
    private var currentTextEditingView: TextEditingView?
    private var fontSizeSlider: Slider = Slider().forAutoLayout()
    private let penToolView: PenToolView = PenToolView().forAutoLayout()
    private let gradientBackground = GradientBackgroundView().forAutoLayout()
    private let colorPickerButton: ColorPickerButton = ColorPickerButton().forAutoLayout()
    private var legacyPickerHolder: LegacyColorPickerHolderView?
    
    private var fontSliderLeadingOffset: CGFloat = .zero
    private var textGestureRecognizers: [UIView: Set<UIGestureRecognizer>] = [:]
    private var textTransforms: [UIView: CGAffineTransform] = [:]
    
    private var currentPenWidth: Float = 1 {
        didSet {
            penToolView.width = CGFloat(currentPenWidth)
            updateDrawingTool()
        }
    }
    var currentColor: UIColor = .white {
        didSet {
            keyboardAccessory.globalColor = currentColor
            colorPickerButton.color = currentColor
            penToolView.color = currentColor
            updateDrawingTool()
        }
    }
    
    var isAdjustingPenWidth: Bool = false
    
    private var textEditingGesture: UITapGestureRecognizer?
    
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
    private let sliderWidth: CGFloat = 32
    private let maxPenWidth: Float = 48
    
    let springDamping: CGFloat = 0.85
    let initialSpringVelocity: CGFloat = 2
    
    private let hiddenButtonTransform: CGAffineTransform = CGAffineTransform(scaleX: 0.2, y: 0.2)
    private let initialToolTransform: CGAffineTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    private let hiddenToolTransform: CGAffineTransform = CGAffineTransform(translationX: .zero, y: .xxxl)
    private var selectedToolTransform: CGAffineTransform {
        return CGAffineTransform(
            translationX: (bounds.width - penToolView.frame.width).half - penToolView.frame.minX,
            y: .zero
        ).scaledBy(x: 1.2, y: 1.2)
    }
    
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
    
    // drawing methods
    
    func setDrawing(_ drawing: PKDrawing) {
        let tempDelegate = drawingCanvas.delegate
        drawingCanvas.delegate = nil
        drawingCanvas.drawing = drawing
        drawingCanvas.delegate = tempDelegate
    }
    
    func selectPenTool() {
        hideLegacyPicker()
        withSpringAnimation {
            self.penToolView.transform = self.selectedToolTransform
            self.colorPickerButton.transform = self.hiddenButtonTransform
            self.saveButton.transform = self.hiddenButtonTransform
            self.colorPickerButton.alpha = .zero
            self.saveButton.alpha = .zero
        } completion: {
            self.isAdjustingPenWidth = true
        }
        morphControl.setMode(.slider)
        exitButton.setMode(.back, animated: true)
    }
    
    func deselectPenTool() {
        withSpringAnimation {
            self.penToolView.transform = self.initialToolTransform
            self.colorPickerButton.transform = .identity
            self.saveButton.transform = .identity
            self.colorPickerButton.alpha = .one
            self.saveButton.alpha = .one
        } completion: {
            self.isAdjustingPenWidth = false
        }
        morphControl.setMode(.segmentedControl)
        exitButton.setMode(.close, animated: true)
    }
    
    func startDrawing() {
        textEditingGesture?.isEnabled = false
        guard !canvasView.subviews.contains(drawingCanvas) else {
            updateDrawingTool()
            canvasView.becomeFirstResponder()
            return
        }
        
        canvasView.addSubview(drawingCanvas)
        [
            drawingCanvas.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
            drawingCanvas.topAnchor.constraint(equalTo: canvasView.topAnchor),
            drawingCanvas.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
            drawingCanvas.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor)
        ].activate()
        
        drawingCanvas.isOpaque = false
        drawingCanvas.backgroundColor = .clear
        drawingCanvas.drawing = PKDrawing()
        if #available(iOS 14.0, *) {
            drawingCanvas.drawingPolicy = .anyInput
        } else {
            drawingCanvas.allowsFingerDrawing = true
        }
        updateDrawingTool()
        drawingCanvas.becomeFirstResponder()
    }
    
    private func updateDrawingTool() {
        let tool = PKInkingTool(.pen, color: currentColor, width: CGFloat(currentPenWidth))
        drawingCanvas.tool = tool
    }
    
    // text editing methods
    
    func startEditingText(with config: LabelContainerViewConfiguration) -> TextEditingView? {
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
        fontSliderLeadingOffset = -sliderWidth.half + .one.doubled
        UIView.animate(withDuration: Durations.half) {
            textEditingView.alpha = .one
            self.layoutIfNeeded()
        }
        
        textEditingView.labelInputContainer.labelTextView.becomeFirstResponder()
        
        currentTextEditingView = textEditingView
        return textEditingView
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
    
    // common
    
    func setupView(for mode: EditorMode) {
        switch mode {
        case .draw:
            withSpringAnimation {
                self.keyboardAccessory.transform = self.hiddenToolTransform
                self.penToolView.transform = self.initialToolTransform
                self.keyboardAccessory.alpha = .zero
                self.penToolView.alpha = .one
            }
        case .text:
            withSpringAnimation {
                self.penToolView.transform = self.hiddenToolTransform
                self.keyboardAccessory.transform = .identity
                self.keyboardAccessory.alpha = .one
                self.penToolView.alpha = .zero
            }
        }
    }

    
    func showLegacyPicker() -> LegacyColorPicker? {
        setupLegacyPickerViewIfNeeded()
        textEditingGesture?.isEnabled = false
        legacyPickerHolder?.isHidden = false
        legacyPickerHolder?.showPicker(dimsBackground: currentTextEditingView == nil)
        
        return legacyPickerHolder?.pickerView
    }
    
    func hideLegacyPicker() {
        legacyPickerHolder?.hidePicker {
            self.legacyPickerHolder?.isHidden = true
            self.textEditingGesture?.isEnabled = true
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
        setupKeyboardAccessory()
        setupPenToolView()
        setupColorPickerButton()
        setupEditingGesture()
    }
    
    private func setupEditingGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleEditingGesture(gestureRecognizer:)))
        gesture.delegate = self
        textEditingGesture = gesture
        canvasView.addGestureRecognizer(gesture)
    }
    
    private func addSubviews() {
        addSubview(containerView)
        addSubview(canvasView)
        addSubview(keyboardAccessory)
        addSubview(penToolView)
        addSubview(gradientBackground)
        addSubview(colorPickerButton)
        addSubview(exitButton)
        addSubview(saveButton)
        addSubview(morphControl)
        addSubview(fontSizeSlider)
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
            
            colorPickerButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: .s),
            colorPickerButton.widthAnchor.constraint(equalToConstant: .l),
            colorPickerButton.heightAnchor.constraint(equalToConstant: .l),
            colorPickerButton.centerYAnchor.constraint(equalTo: keyboardAccessory.centerYAnchor),
            
            keyboardAccessory.leadingAnchor.constraint(equalTo: colorPickerButton.trailingAnchor, constant: .s),
            keyboardAccessory.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            keyboardAccessory.heightAnchor.constraint(equalToConstant: .xxl),
            accessoryViewOffsetConstraint,
            
            penToolView.leadingAnchor.constraint(equalTo: morphControl.leadingAnchor),
            penToolView.bottomAnchor.constraint(equalTo: morphControl.topAnchor, constant: -.xxs),
            
            gradientBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientBackground.topAnchor.constraint(equalTo: exitButton.topAnchor),
            
            exitButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: .s),
            exitButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.m),
            exitButton.widthAnchor.constraint(equalToConstant: .l),
            exitButton.heightAnchor.constraint(equalToConstant: .l),
            
            saveButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -.s),
            saveButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.m),
            saveButton.widthAnchor.constraint(equalToConstant: .l),
            saveButton.heightAnchor.constraint(equalToConstant: .l),
            
            morphControl.leadingAnchor.constraint(equalTo: exitButton.trailingAnchor, constant: .s),
            morphControl.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -.s),
            morphControl.centerYAnchor.constraint(equalTo: exitButton.centerYAnchor)
        ].compactMap { $0 }.activate()
    }
    
    private func setupExitButton() {
        exitButton.setMode(.close, animated: false)
        exitButton.addTarget(self, action: #selector(handleExitTap), for: .touchUpInside)
        exitButton.adjustsImageWhenHighlighted = false
    }
    
    private func setupSaveButton() {
        saveButton.addTarget(self, action: #selector(handleSaveTap), for: .touchUpInside)
        saveButton.setImage(Asset.Icons.save.image, for: .normal)
        saveButton.tintColor = .white
        saveButton.adjustsImageWhenHighlighted = false
    }
    
    private func setupPenToolView() {
        penToolView.color = currentColor
        penToolView.width = CGFloat(currentPenWidth)
        penToolView.transform = hiddenToolTransform
        penToolView.alpha = 0.001
        penToolView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePenTap)))
    }
    
    private func setupKeyboardAccessory() {
        keyboardAccessory.transform = hiddenToolTransform
        keyboardAccessory.alpha = .zero
    }
    
    private func setupSegmentedControl() {
        morphControl.configure(
            with: MorphingSlider.Model(
                sliderValue: currentPenWidth,
                segmentedControlModel: SegmentedControl.Model(
                    items: [
                        L10n.Screens.Editor.Modes.draw,
                        L10n.Screens.Editor.Modes.text
                    ],
                    cornerRadius: .s
                )
            )
        )
        morphControl.slider.minimumValue = 1
        morphControl.slider.maximumValue = maxPenWidth
        morphControl.slider.delegate = self
        morphControl.segmentedControl.delegate = self
    }
    
    private func setupSlider() {
        fontSizeSlider.minimumValue = sliderMinValue
        fontSizeSlider.maximumValue = sliderMaxValue
        fontSliderLeadingOffset = -sliderWidth
        
        fontSizeSlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        
        fontSizeSlider.delegate = self
    }
    
    private func setupColorPickerButton() {
        colorPickerButton.addTarget(self, action: #selector(handleColorPickerTap), for: .touchUpInside)
    }
    
    private func updateSliderFrame() {
        fontSizeSlider.frame = CGRect(
            x: containerView.frame.minX + fontSliderLeadingOffset,
            y: containerView.frame.minY + (containerView.frame.height - sliderHeight).half,
            width: sliderWidth,
            height: sliderHeight
        )
    }
    
    private func setupLegacyPickerViewIfNeeded() {
        guard legacyPickerHolder == nil else { return }
        let picker = LegacyColorPickerHolderView().forAutoLayout()
        insertSubview(picker, aboveSubview: canvasView)
        [
            picker.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
            picker.topAnchor.constraint(equalTo: canvasView.topAnchor),
            picker.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor)
        ].activate()
        layoutIfNeeded()
        legacyPickerHolder = picker
    }
    
    func moveTextViewsToInactiveStatus() {
        canvasView.subviews.compactMap { $0 as? TextEditingView }.forEach {
            $0.labelInputContainer.state = .inactive // visually
            $0.isUserInteractionEnabled = false
        }
    }
    
    func moveTextViewsToActiveStatus() {
        textEditingGesture?.isEnabled = true
        canvasView.subviews.compactMap { $0 as? TextEditingView }.forEach {
            $0.labelInputContainer.state = .static
            $0.isUserInteractionEnabled = true
        }
    }
    
    private func withSpringAnimation(duration: TimeInterval = Durations.single, _ action: @escaping Producer<Void>, completion: Producer<Void>? = nil) {
        UIView.animate(
            withDuration: Durations.single,
            delay: .zero,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: initialSpringVelocity,
            options: []
        ) {
            action()
        } completion: { _ in
            completion?()
        }
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
    
    func valueChanged(_ slider: Slider, to newValue: Float) {
        if slider == fontSizeSlider {
            guard let editingView = currentTextEditingView else { return }
            editingView.labelInputContainer.fontScale = newValue
        } else if slider == morphControl.slider {
            currentPenWidth = newValue
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == textEditingGesture && !drawingCanvas.isUserInteractionEnabled {
            return true
        }
        
        if let other = otherGestureRecognizer as? UIPanGestureRecognizer,
           other.minimumNumberOfTouches == 1 {
            return false
        } else {
            return true
        }
    }
    
    @objc private func handleEditingGesture(gestureRecognizer: UITapGestureRecognizer) {
        let tappedView = hitTest(gestureRecognizer.location(in: self), with: nil)
        if (tappedView as? LabelTextView) == nil {
            delegate?.requestStartEditing()
        }
    }
    
    @objc private func handleExitTap() {
        delegate?.didTapExitButton()
    }
    
    @objc private func handleSaveTap() {
        delegate?.didTapSaveButton()
    }
    
    @objc private func handlePenTap() {
        guard !isAdjustingPenWidth else { return }
        selectPenTool()
    }
    
    @objc private func handleColorPickerTap() {
        delegate?.didTapColorPickerButton(colorPickerButton)
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
