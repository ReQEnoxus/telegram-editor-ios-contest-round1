//
//  LegacyColorPickerHolderView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 31.10.2022.
//

import Foundation
import UIKit

final class LegacyColorPickerHolderView: UIView {
    private enum Constants {
        static let sliderHeight: CGFloat = 240
        static let sliderWidth: CGFloat = 32
    }
    
    let pickerView: LegacyColorPicker = LegacyColorPicker().forAutoLayout()
    private var pickerViewOffsetConstraint: NSLayoutConstraint?
    
    func showPicker(dimsBackground: Bool = true) {
        pickerViewOffsetConstraint?.constant = .zero
        UIView.animate(
            withDuration: Durations.single,
            delay: .zero,
            options: .curveEaseOut,
            animations: {
                if dimsBackground {
                    self.backgroundColor = .black.withAlphaComponent(.one.half)
                }
                self.pickerView.alpha = .one
                self.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    func hidePicker(completion: Producer<Void>? = nil) {
        pickerViewOffsetConstraint?.constant = Constants.sliderWidth
        UIView.animate(
            withDuration: Durations.single,
            delay: .zero,
            options: .curveEaseOut,
            animations: {
                self.pickerView.alpha = .zero
                self.backgroundColor = .clear
                self.layoutIfNeeded()
            },
            completion: { _ in completion?() }
        )
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
        addSubviews()
        makeConstraints()
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    private func addSubviews() {
        addSubview(pickerView)
    }
    
    private func makeConstraints() {
        pickerViewOffsetConstraint = pickerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.sliderWidth)
        [
            pickerViewOffsetConstraint,
            pickerView.heightAnchor.constraint(equalToConstant: Constants.sliderHeight),
            pickerView.widthAnchor.constraint(equalToConstant: Constants.sliderWidth),
            pickerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ].compactMap { $0 }.activate()
    }
    
    @objc private func handleTap() {
        hidePicker()
        pickerView.delegate?.legacyColorPickerDidDismiss(pickerView)
    }
}

extension LegacyColorPickerHolderView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        return !pickerView.point(inside: pickerView.convert(point, from: self), with: nil)
    }
}
