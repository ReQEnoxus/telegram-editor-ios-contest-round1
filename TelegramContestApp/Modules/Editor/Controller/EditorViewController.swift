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
    let transitionController = EditorTransitionController()
    
    private let asset: PHAsset
    private let service: LibraryServiceProtocol
    
    private let editorView = EditorView<PhotoContainerView>().forAutoLayout()
    
    init(asset: PHAsset, service: LibraryServiceProtocol) {
        self.asset = asset
        self.service = service
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overCurrentContext
        transitioningDelegate = transitionController
        editorView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(editorView)
        editorView.containerView.alpha = .zero
        [
            editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ].activate()
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
        return AVMakeRect(
            aspectRatio: image.size,
            insideRect: CGRect(
                x: rect.origin.x,
                y: rect.origin.y + editorView.topInset,
                width: rect.width,
                height: rect.height - editorView.topInset - editorView.bottomInset - .l - .m
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
        
    }
}
