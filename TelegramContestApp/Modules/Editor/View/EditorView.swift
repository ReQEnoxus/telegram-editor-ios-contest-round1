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

final class EditorView<Container: ContainerView>: UIView, SegmentedControlDelegate {
    var topInset: CGFloat {
        return 0.1 * UIScreen.main.bounds.height
    }
    var bottomInset: CGFloat {
        return 0.13 * UIScreen.main.bounds.height
    }
    
    let containerView: Container = Container().forAutoLayout()
    private let exitButton: UIButton = UIButton(type: .custom).forAutoLayout()
    private let saveButton: UIButton = UIButton(type: .custom).forAutoLayout()
    private let segmentedControl: SegmentedControl = SegmentedControl().forAutoLayout()
    private var canvasTopInsetConstraint: NSLayoutConstraint?
    private var canvasBottomInsetConstraint: NSLayoutConstraint?
    
    weak var delegate: EditorViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMedia(with media: Container.Media) {
        containerView.updateMedia(with: media)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        canvasTopInsetConstraint?.constant = topInset
        canvasBottomInsetConstraint?.constant = -bottomInset
    }
    
    private func commonInit() {
        backgroundColor = .black
        addSubviews()
        makeConstraints()
        setupExitButton()
        setupSaveButton()
        setupSegmentedControl()
    }
    
    private func addSubviews() {
        addSubview(containerView)
        addSubview(exitButton)
        addSubview(saveButton)
        addSubview(segmentedControl)
    }
    
    private func makeConstraints() {
        canvasTopInsetConstraint = containerView.topAnchor.constraint(equalTo: topAnchor, constant: topInset)
        canvasBottomInsetConstraint = containerView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -bottomInset)
        [
            canvasTopInsetConstraint,
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasBottomInsetConstraint,
            
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
    
    func didChangeSelectedIndex(_ index: Int) {
        guard let currentMode = EditorMode(rawValue: index) else { return }
        delegate?.didChangeEditorMode(currentMode)
    }
    
    @objc private func handleExitTap() {
        delegate?.didTapExitButton()
    }
    
    @objc private func handleSaveTap() {
        delegate?.didTapSaveButton()
    }
}
