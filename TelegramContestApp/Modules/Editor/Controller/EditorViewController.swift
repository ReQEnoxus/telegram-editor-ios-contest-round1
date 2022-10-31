//
//  EditorViewController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit
import Photos
import PencilKit

final class EditorViewController: UIViewController {
    var transitionController: EditorTransitionController? {
        return (navigationController as? EditorNavigationController)?.transitionController
    }
    
    private var resultImage: UIImage?
    private let asset: PHAsset
    private let service: LibraryServiceProtocol
    private let renderService: RenderServiceProtocol
    private let initialImage: UIImage?
    
    private let editorView = EditorView<PhotoContainerView>().forAutoLayout()
    
    private var currentFontItems: [FontCustomizationAccessoryViewConfiguration.FontItem] = []
    private var currentTextAlignment: TextAlignment = .left
    private var currentEditingField: TextEditingView?
    private var temporaryIgnoreKeyboardEvents: Bool = false
    private let acitvityIndicator = UIActivityIndicatorView(style: .large).forAutoLayout()
    
    private var navbarMode: NavbarMode = .regular {
        didSet {
            setupNavbarMode()
            updateNavbar()
        }
    }
    
    private var currentEditorMode: EditorMode = .draw
    
    private var showsLegacyPickerView: Bool = false
    
    // Undo/Clear
    private var actionTypes: [EditingAction] = [] {
        didSet {
            updateNavbar()
        }
    }
    private var drawingSteps: [PKDrawing] = []
    private var editedLabels: [UIView] = []
    
    private var lastAction: EditingAction? {
        return actionTypes.last
    }
    
    init(
        asset: PHAsset,
        service: LibraryServiceProtocol,
        renderService: RenderServiceProtocol,
        initialImage: UIImage?
    ) {
        self.asset = asset
        self.service = service
        self.renderService = renderService
        self.initialImage = initialImage
        super.init(nibName: nil, bundle: nil)
        editorView.delegate = self
        currentFontItems = [
            FontCustomizationAccessoryViewConfiguration.FontItem(
                font: .systemFont(ofSize: .m),
                name: "SF Pro Display",
                isSelected: true
            ),
            FontCustomizationAccessoryViewConfiguration.FontItem(
                font: FontFamily.Montserrat.regular.font(size: .m),
                name: "Montserrat",
                isSelected: false
            ),
            FontCustomizationAccessoryViewConfiguration.FontItem(
                font: FontFamily.Ubuntu.regular.font(size: .m),
                name: "Ubuntu",
                isSelected: false
            ),
            FontCustomizationAccessoryViewConfiguration.FontItem(
                font: FontFamily.Roboto.regular.font(size: .m),
                name: "Roboto",
                isSelected: false
            )
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(editorView)
        configureNavbar()
        editorView.containerView.alpha = .zero
        [
            editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ].activate()
        navbarMode = .regular
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillOpen),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillClose),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        view.addSubview(acitvityIndicator)
        [
            acitvityIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            acitvityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            acitvityIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            acitvityIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ].activate()
        acitvityIndicator.isHidden = true
        editorView.drawingCanvas.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMedia(with: initialImage)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        editorView.containerView.alpha = .one
        setupInitialToolset()
        service.fetchImage(from: asset, targetSize: PHImageManagerMaximumSize) { [weak self] loaded in
            self?.updateMedia(with: loaded.image)
        }
        
        setupForCurrentMode()
    }
    
    private func updateMedia(with image: UIImage?) {
        guard let image = image else { return }
        editorView.updateMedia(with: image)
        let targetImageRect = AVMakeRect(aspectRatio: image.size, insideRect: editorView.containerView.bounds)
        editorView.imageSize = targetImageRect.size
    }
    
    private func setupInitialToolset() {
        
        editorView.setupView(for: .draw)
    }
    
    // MARK: - Navbar
    
    private func configureNavbar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupNavbarMode() {
        switch navbarMode {
        case .regular:
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: Asset.Icons.undo.image,
                style: .plain,
                target: self,
                action: #selector(handleLeftButtonTap)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: L10n.Screens.Editor.Navbar.clearAll,
                style: .plain,
                target: self,
                action: #selector(handleRightButtonTap)
            )
        case .textEditing:
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: L10n.Screens.Editor.Navbar.cancel,
                style: .plain,
                target: self,
                action: #selector(handleLeftButtonTap)
            )
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: L10n.Screens.Editor.Navbar.done,
                style: .done,
                target: self,
                action: #selector(handleRightButtonTap)
            )
        }
        navigationItem.leftBarButtonItem?.tintColor = .white
        navigationItem.rightBarButtonItem?.tintColor = .white
    }
    
    private func updateNavbar() {
        switch navbarMode {
        case .regular:
            navigationItem.leftBarButtonItem?.isEnabled = !actionTypes.isEmpty
            navigationItem.rightBarButtonItem?.isEnabled = !actionTypes.isEmpty
            editorView.saveButton.isEnabled = !actionTypes.isEmpty
            
        case .textEditing:
            navigationItem.leftBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.isEnabled = currentEditingField?.labelInputContainer.labelTextView.text.isEmpty == false
        }
    }
    
    @objc private func handleLeftButtonTap() {
        switch navbarMode {
        case .regular:
            performUndo()
        case .textEditing:
            editorView.discardCurrentlyEditingText()
            navbarMode = .regular
        }
    }
    
    @objc private func handleRightButtonTap() {
        switch navbarMode {
        case .regular:
            clearAll()
        case .textEditing:
            saveText(currentEditingField)
            navbarMode = .regular
            editorView.saveCurrentlyEditingText()
        }
    }
    
    @objc private func keyboardWillOpen(notification: NSNotification) {
        guard !temporaryIgnoreKeyboardEvents else { return }
        guard let userInfo = notification.userInfo,
              let keyboardSize: CGSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        editorView.keyboardHeight = keyboardSize.height
        let imageBottomY = view.frame.height - view.convert(editorView.containerView.bounds, from: editorView.containerView).maxY
        if imageBottomY < keyboardSize.height {
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            editorView.additionalBottomInset = keyboardSize.height - imageBottomY
            UIView.animate(withDuration: duration) {
                self.editorView.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillClose(notification: NSNotification) {
        guard !temporaryIgnoreKeyboardEvents else { return }
        guard let userInfo = notification.userInfo else { return }
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        editorView.additionalBottomInset = .zero
        editorView.keyboardHeight = .zero
        UIView.animate(withDuration: duration) {
            self.editorView.layoutIfNeeded()
        }
    }
    
    private func setupForCurrentMode() {
        switch currentEditorMode {
        case .draw:
            navbarMode = .regular
            currentEditingField = nil
            editorView.drawingCanvas.isUserInteractionEnabled = true
            editorView.moveTextViewsToInactiveStatus()
            editorView.startDrawing()
        case .text:
            editorView.drawingCanvas.isUserInteractionEnabled = false
            editorView.moveTextViewsToActiveStatus()
            if currentEditingField == nil && editedLabels.isEmpty {
                startNewEditing()
            }
        }
    }
    
    private func startNewEditing() {
        navbarMode = .textEditing
        editorView.keyboardAccessory.configure(
            with: FontCustomizationAccessoryViewConfiguration(
                fontItems: currentFontItems,
                textAlignment: currentTextAlignment
            )
        )
        currentEditingField = editorView.startEditingText(
            with: LabelContainerViewConfiguration(
                labelConfiguration: LabelTextViewConfiguration(
                    initialTextColor: editorView.keyboardAccessory.globalColor
                ),
                outlineInset: .xxs
            )
        )
        if let font = currentFontItems.first(where: { $0.isSelected }) ?? currentFontItems.first {
            currentEditingField?.labelInputContainer.labelTextView.setFont(font.font)
        }
        currentEditingField?.labelInputContainer.labelTextView.textAlignment = editorView.keyboardAccessory.textAlignment.nsTextAlignment
        currentEditingField?.labelInputContainer.labelTextView.didChangeOutlineMode(from: editorView.keyboardAccessory.outlineConfig, to: editorView.keyboardAccessory.outlineConfig, shouldAnimate: false)
        editorView.keyboardAccessory.delegate = self
        currentEditingField?.labelInputContainer.labelTextView.accessoryDelegate = self
    }
}

extension EditorViewController: TransitionDelegate {
    func reference() -> ViewReference? {
        guard let image = resultImage ?? editorView.containerView.imageView.image else { return nil }
        let initialFrame = view.convert(editorView.containerView.bounds, from: editorView.containerView)
        let targetFrame = AVMakeRect(
            aspectRatio: image.size,
            insideRect: CGRect(
                x: initialFrame.origin.x,
                y: initialFrame.origin.y + editorView.topInset,
                width: initialFrame.width,
                height: initialFrame.height - editorView.topInset - editorView.bottomInset
            )
        )
        return ViewReference(view: editorView.containerView, image: image, frame: targetFrame)
    }
    
    func referenceFrame(for image: UIImage, in rect: CGRect) -> CGRect? {
        let navBarHeight = navigationController?.navigationBar.frame.height ?? .zero
        return AVMakeRect(
            aspectRatio: image.size,
            insideRect: CGRect(
                x: rect.origin.x,
                y: rect.origin.y + editorView.topInset + navBarHeight,
                width: rect.width,
                height: rect.height - editorView.topInset - editorView.bottomInset - .l - .m - navBarHeight
            )
        )
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        editorView.setNeedsUpdateConstraints()
    }
    
    @available(iOS 14, *)
    private func showModernColorPicker() {
        let colorPickerController = UIColorPickerViewController()
        colorPickerController.selectedColor = editorView.currentColor
        colorPickerController.view.tintColor = .white
        colorPickerController.overrideUserInterfaceStyle = .dark
        colorPickerController.supportsAlpha = false // to match legacy picker
        colorPickerController.delegate = self
        temporaryIgnoreKeyboardEvents = true
        navigationController?.present(colorPickerController, animated: true, completion: nil)
    }
    
    private func showLegacyColorPicker() {
        let picker = editorView.showLegacyPicker()
        picker?.delegate = self
    }
}

extension EditorViewController: EditorViewDelegate {
    func requestStartEditing() {
        startNewEditing()
    }
    
    func didTapExitButton() {
        if editorView.isAdjustingPenWidth {
            editorView.deselectPenTool()
        } else {
            if !actionTypes.isEmpty {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(
                    UIAlertAction(
                        title: L10n.Screens.Editor.Alert.scrapAll,
                        style: .destructive,
                        handler: { _ in
                            self.drawingSteps.removeAll()
                            self.editedLabels.forEach { $0.removeFromSuperview() }
                            self.editedLabels.removeAll()
                            self.editorView.drawingCanvas.drawing = PKDrawing()
                            self.actionTypes.removeAll()
                            self.dismiss(animated: true, completion: nil)
                            self.editorView.containerView.alpha = .zero
                        }
                    )
                )
                alert.addAction(
                    UIAlertAction(
                        title: L10n.Screens.Editor.Alert.cancel,
                        style: .cancel,
                        handler: { _ in
                            self.temporaryIgnoreKeyboardEvents = false
                        }
                    )
                )
                alert.overrideUserInterfaceStyle = .dark
                
                temporaryIgnoreKeyboardEvents = true
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func didTapSaveButton() {
        guard let image = editorView.containerView.imageView.image else { return }
        editorView.prepare()
        acitvityIndicator.isHidden = false
        acitvityIndicator.startAnimating()
        switch asset.mediaType {
        case .image:
            renderService.renderImage(image, canvas: editorView.canvasView.layer) { [weak self] resultImage in
                self?.service.save(image: resultImage, completion: { success in
                    DispatchQueue.main.async {
                        if success {
                            self?.acitvityIndicator.isHidden = true
                            self?.acitvityIndicator.stopAnimating()
                            self?.resultImage = resultImage
                            NotificationCenter.default.post(name: .exportFinished, object: nil)
                        } else {
                            // handle error
                        }
                    }
                })
            }
        case .video:
            renderService.renderVideo(asset, refImage: image, canvas: editorView.canvasView.layer) { [weak self] tempURL in
                // save to phimage
                self?.service.save(video: tempURL, completion: { success in
                    DispatchQueue.main.async {
                        self?.acitvityIndicator.isHidden = true
                        self?.acitvityIndicator.stopAnimating()
                        if success {
                            NotificationCenter.default.post(name: .exportFinished, object: nil)
                        } else {
                            // handle error
                        }
                    }
                })
            }
            
        default:
            break
        }
    }
    
    func didChangeEditorMode(_ mode: EditorMode) {
        currentEditorMode = mode
        updateNavbar()
        editorView.setupView(for: mode)
        setupForCurrentMode()
    }
    
    func didTapColorPickerButton(_ button: ColorPickerButton) {
        // picker
        if #available(iOS 14, *) {
            showModernColorPicker()
        } else {
            if showsLegacyPickerView {
                editorView.hideLegacyPicker()
            } else {
                showLegacyColorPicker()
            }
            showsLegacyPickerView.toggle()
        }
    }
}

extension EditorViewController: FontCustomizationAccessoryViewDelegate {
    func didChangeGlobalColor(to color: UIColor, usingCustomOutline: Bool) {
        currentEditingField?.labelInputContainer.labelTextView.didChangeGlobalColor(to: color, usingCustomOutline: usingCustomOutline)
    }
    
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem) {
        currentEditingField?.labelInputContainer.labelTextView.didChangeFont(newFont)
    }
    
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment) {
        currentEditingField?.labelInputContainer.labelTextView.didChangeTextAlignment(from: old, to: new)
    }
    
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool) {
        currentEditingField?.labelInputContainer.labelTextView.didChangeOutlineMode(from: outline, to: targetOutline, shouldAnimate: shouldAnimate)
    }
}

extension EditorViewController: AccessoryViewOperatingDelegate {
    func updateAccessory(selectedFont: UIFont, selectedAlignment: NSTextAlignment) {
        updateNavbar()
        currentTextAlignment = TextAlignment.from(nsTextAlignment: selectedAlignment)
        currentFontItems = currentFontItems.map {
            FontCustomizationAccessoryViewConfiguration.FontItem(
                font: $0.font,
                name: $0.name,
                isSelected: selectedFont == $0.font
            )
        }
        editorView.keyboardAccessory.configure(
            with: FontCustomizationAccessoryViewConfiguration(
                fontItems: currentFontItems,
                textAlignment: currentTextAlignment
            )
        )
    }
}

extension EditorViewController: PKCanvasViewDelegate {
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        let newDrawing = canvasView.drawing
        saveDrawing(newDrawing)
    }
}

@available(iOS 14.0, *)
extension EditorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        editorView.currentColor = viewController.selectedColor
    }
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        editorView.currentColor = color
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        temporaryIgnoreKeyboardEvents = false
    }
}

extension EditorViewController: LegacyColorPickerDelegate {
    
    func legacyColorPicker(_ picker: LegacyColorPicker, didSelect color: UIColor) {
        editorView.currentColor = color
    }
    
    func legacyColorPickerDidDismiss(_ picker: LegacyColorPicker) {
        showsLegacyPickerView = false
        if currentEditorMode == .draw {
            editorView.startDrawing()
        }
    }
}

extension EditorViewController {
    // undo redo logic
    func saveDrawing(_ drawing: PKDrawing) {
        drawingSteps.append(drawing)
        actionTypes.append(.draw)
    }
    
    func saveText(_ view: UIView?) {
        guard let view = view else { return }
        editedLabels.append(view)
        actionTypes.append(.text)
    }
    
    func performUndo() {
        guard let lastAction = lastAction else { return }
        switch lastAction {
        case .draw:
            editorView.setDrawing(drawingSteps.popLast() ?? PKDrawing())
        case .text:
            let lastEdited = editedLabels.popLast()
            lastEdited?.removeFromSuperview()
        }
        _ = actionTypes.popLast()
    }
    
    func clearAll() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(
            UIAlertAction(
                title: L10n.Screens.Editor.Alert.clearAll,
                style: .destructive,
                handler: { _ in
                    self.drawingSteps.removeAll()
                    self.editedLabels.forEach { $0.removeFromSuperview() }
                    self.editedLabels.removeAll()
                    self.editorView.drawingCanvas.drawing = PKDrawing()
                    self.actionTypes.removeAll()
                    self.temporaryIgnoreKeyboardEvents = false
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Screens.Editor.Alert.cancel,
                style: .cancel,
                handler: { _ in
                    self.temporaryIgnoreKeyboardEvents = false
                }
            )
        )
        alert.overrideUserInterfaceStyle = .dark
        
        temporaryIgnoreKeyboardEvents = true
        present(alert, animated: true, completion: nil)
    }
}
