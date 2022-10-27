//
//  SegmentView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 27.10.2022.
//

import Foundation
import UIKit

final class SegmentView: UIView {
    private enum Constants {
        static let fontSize: CGFloat = 14
    }
    
    var text: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }
    
    private let label: UILabel = UILabel().forAutoLayout()
    
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
        setupLabel()
    }
    
    private func addSubviews() {
        addSubview(label)
    }
    
    private func makeConstraints() {
        [
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .s),
            label.topAnchor.constraint(equalTo: topAnchor, constant: .xxs),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.s),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.xxs)
        ].activate()
    }
    
    private func setupLabel() {
        label.font = .systemFont(ofSize: Constants.fontSize, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
    }
}
