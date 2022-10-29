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
    
    private let asset: PHAsset
    private let service: LibraryServiceProtocol
    private let editorView = EditorView<PhotoContainerView>().forAutoLayout()
    
    private var navbarMode: NavbarMode = .regular {
        didSet {
            setupNavbarMode()
            updateNavbar()
        }
    }
    
    init(asset: PHAsset, service: LibraryServiceProtocol) {
        self.asset = asset
        self.service = service
        super.init(nibName: nil, bundle: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NAZAD", style: .plain, target: nil, action: nil)
        editorView.delegate = self
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
            self?.editorView.updateMedia(with: loaded.image)
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
        guard let userInfo = notification.userInfo else { return }
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        editorView.additionalBottomInset = .zero
        
        UIView.animate(withDuration: duration) {
            self.editorView.layoutIfNeeded()
        }
    }
}

extension EditorViewController: TransitionDelegate {
    func reference() -> ViewReference? {
        guard let image = editorView.containerView.imageView.image else { return nil }
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
        
    }
    
    func didChangeEditorMode(_ mode: EditorMode) {
        updateNavbar()
        switch mode {
        case .draw:
            navbarMode = .regular
        case .text:
            navbarMode = .textEditing
            editorView.startEditingText(
                with: LabelContainerViewConfiguration(
                    labelConfiguration: LabelTextViewConfiguration(
                        supportedFonts: [
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
                    ),
                    outlineInset: .m
                )
            )
        }
    }
}
