//
//  TextEditingView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 29.10.2022.
//

import Foundation
import UIKit

final class TextEditingView: UIView {
    private enum Constants {
        static let handleSize: CGSize = CGSize(width: 15, height: 15)
    }
    enum TouchType {
        case inside
        case leftHandle
        case rightHandle
        case outside
    }
    
    let labelInputContainer: LabelInputContainerView = LabelInputContainerView().forAutoLayout()
    
    func touchType(for point: CGPoint) -> TouchType {
        let leftHandleRect = CGRect(
            x: labelInputContainer.frame.minX - Constants.handleSize.width.half,
            y: labelInputContainer.frame.midY - Constants.handleSize.height.half,
            width: Constants.handleSize.width,
            height: Constants.handleSize.height
        )
        
        let rightHandleRect = CGRect(
            x: labelInputContainer.frame.maxX - Constants.handleSize.width.half,
            y: labelInputContainer.frame.midY - Constants.handleSize.height.half,
            width: Constants.handleSize.width,
            height: Constants.handleSize.height
        )
        
        if leftHandleRect.contains(point) {
            return .leftHandle
        } else if rightHandleRect.contains(point) {
            return .rightHandle
        } else if labelInputContainer.frame.contains(point) {
            return .inside
        } else {
            return .outside
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func commonInit() {
        backgroundColor = .black.withAlphaComponent(.one.half)
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        addSubview(labelInputContainer)
    }
    
    private func makeConstraints() {
        [
            labelInputContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelInputContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelInputContainer.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -.s)
        ].activate()
    }
}
