//
//  EditorViewController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit
import Photos

final class EditorViewController: UIViewController {
    var transitionController: EditorTransitionController? {
        return (navigationController as? EditorNavigationController)?.transitionController
    }
    
    private var resultImage: UIImage?
    private let asset: PHAsset
    private let service: LibraryServiceProtocol
    private let renderService: RenderServiceProtocol
    private let editorView = EditorView<PhotoContainerView>().forAutoLayout()
    
    private var currentFontItems: [FontCustomizationAccessoryViewConfiguration.FontItem] = []
    private var currentTextAlignment: TextAlignment = .left
    private var currentEditingField: LabelTextView?
    
    private var navbarMode: NavbarMode = .regular {
        didSet {
            setupNavbarMode()
            updateNavbar()
        }
    }
    
    init(
        asset: PHAsset,
        service: LibraryServiceProtocol,
        renderService: RenderServiceProtocol
    ) {
        self.asset = asset
        self.service = service
        self.renderService = renderService
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        service.fetchImage(from: asset, targetSize: PHImageManagerMaximumSize) { [weak self] loaded in
            guard let self = self, let image = loaded.image else { return }
            self.editorView.updateMedia(with: loaded.image)
            let targetImageRect = AVMakeRect(aspectRatio: image.size, insideRect: self.editorView.containerView.bounds)
            self.editorView.imageSize = targetImageRect.size
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        editorView.containerView.alpha = .one
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
            navigationItem.leftBarButtonItem?.isEnabled = !editorView.canvasView.subviews.isEmpty
            navigationItem.rightBarButtonItem?.isEnabled = !editorView.canvasView.subviews.isEmpty
        case .textEditing:
            navigationItem.leftBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    @objc private func handleLeftButtonTap() {
        switch navbarMode {
        case .regular:
            // TODO: undo
            break
        case .textEditing:
            editorView.discardCurrentlyEditingText()
            navbarMode = .regular
        }
    }
    
    @objc private func handleMiddleButtonTap() {
        
    }
    
    @objc private func handleRightButtonTap() {
        switch navbarMode {
        case .regular:
            // TODO: undo all
            break
        case .textEditing:
            editorView.saveCurrentlyEditingText()
            navbarMode = .regular
        }
    }
    
    @objc private func keyboardWillOpen(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardSize: CGSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        editorView.keyboardHeight = keyboardSize.height
        let imageBottomY = view.frame.height - view.convert(editorView.containerView.bounds, from: editorView.containerView).maxY
        if imageBottomY < keyboardSize.height {
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            editorView.additionalBottomInset = keyboardSize.height - imageBottomY
            UIView.animate(withDuration: duration) {
                self.editorView.keyboardAccessory.setBlur(active: true)
                self.editorView.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillClose(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        editorView.additionalBottomInset = .zero
        editorView.keyboardHeight = .zero
        UIView.animate(withDuration: duration) {
            self.editorView.keyboardAccessory.setBlur(active: false)
            self.editorView.layoutIfNeeded()
        }
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
}

extension EditorViewController: EditorViewDelegate {
    func didTapExitButton() {
        dismiss(animated: true, completion: nil)
        editorView.containerView.alpha = .zero
    }
    
    func didTapSaveButton() {
        guard let image = editorView.containerView.imageView.image else { return }
        editorView.prepare()
        switch asset.mediaType {
        case .image:
            renderService.renderImage(image, canvas: editorView.canvasView.layer) { [weak self] resultImage in
                self?.service.save(image: resultImage, completion: { success in
                    DispatchQueue.main.async {
                        if success {
                            self?.resultImage = resultImage
                            NotificationCenter.default.post(name: .exportFinished, object: nil)
                        } else {
                            // handle error
                        }
                    }
                })
            }
        case .video:
            renderService.renderVideo(asset, canvas: editorView.canvasView.layer) { tempURL in
                // save to phimage
            }
            
        default:
            break
        }
    }
    
    func didChangeEditorMode(_ mode: EditorMode) {
        updateNavbar()
        switch mode {
        case .draw:
            navbarMode = .regular
            currentEditingField = nil
            editorView.startDrawing()
        case .text:
            navbarMode = .textEditing
            if currentEditingField == nil {
                editorView.keyboardAccessory.configure(
                    with: FontCustomizationAccessoryViewConfiguration(
                        fontItems: currentFontItems,
                        textAlignment: currentTextAlignment
                    )
                )
                currentEditingField = editorView.startEditingText(
                    with: LabelContainerViewConfiguration(
                        labelConfiguration: LabelTextViewConfiguration(
                            initialTextColor: .black
                        ),
                        outlineInset: .xxs
                    )
                )
                if let font = currentFontItems.first(where: { $0.isSelected }) ?? currentFontItems.first {
                    currentEditingField?.setFont(font.font)
                }
                currentEditingField?.textAlignment = editorView.keyboardAccessory.textAlignment.nsTextAlignment
                currentEditingField?.didChangeOutlineMode(from: editorView.keyboardAccessory.outlineConfig, to: editorView.keyboardAccessory.outlineConfig, shouldAnimate: false)
                editorView.keyboardAccessory.delegate = self
                currentEditingField?.accessoryDelegate = self
            }
        }
    }
}

extension EditorViewController: FontCustomizationAccessoryViewDelegate {
    func didChangeFont(_ newFont: FontCustomizationAccessoryViewConfiguration.FontItem) {
        currentEditingField?.didChangeFont(newFont)
    }
    
    func didChangeTextAlignment(from old: TextAlignment, to new: TextAlignment) {
        currentEditingField?.didChangeTextAlignment(from: old, to: new)
    }
    
    func didChangeOutlineMode(from outline: OutlineMode, to targetOutline: OutlineMode, shouldAnimate: Bool) {
        currentEditingField?.didChangeOutlineMode(from: outline, to: targetOutline, shouldAnimate: shouldAnimate)
    }
}

extension EditorViewController: AccessoryViewOperatingDelegate {
    func updateAccessory(selectedFont: UIFont, selectedAlignment: NSTextAlignment) {
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
