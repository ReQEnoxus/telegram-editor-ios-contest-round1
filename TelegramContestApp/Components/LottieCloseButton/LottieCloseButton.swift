//
//  LottieCloseButton.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 30.10.2022.
//

import Foundation
import UIKit
import Lottie

final class LottieCloseButton: UIButton {
    enum Mode {
        case back
        case close
    }
    
    private let animationView: LottieAnimationView = LottieAnimationView().forAutoLayout()
    private(set) var mode: Mode = .back
    
    func setMode(_ mode: Mode, animated: Bool) {
        guard mode != self.mode else { return }
        self.mode = mode
        switch mode {
        case .back:
            if animated {
                animationView.play(
                    fromProgress: 0.5,
                    toProgress: 1,
                    loopMode: .playOnce,
                    completion: nil
                )
            } else {
                animationView.currentProgress = .zero
            }
        case .close:
            if animated {
                animationView.play(
                    fromProgress: .zero,
                    toProgress: 0.5,
                    loopMode: .playOnce,
                    completion: nil
                )
            } else {
                animationView.currentProgress = 1
            }
        }
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
        loadAnimation()
    }
    
    private func addSubviews() {
        addSubview(animationView)
    }
    
    private func makeConstraints() {
        [
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.topAnchor.constraint(equalTo: topAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }
    
    private func loadAnimation() {
        var animation: LottieAnimation?
        if let animationUrl = Bundle.main.url(forResource: "backToCancel", withExtension: "json"),
           let animationData = try? Data(contentsOf: animationUrl) {
            animation = try? .from(data: animationData)
        }
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.currentFrame = .zero
        animationView.pause()
        animationView.isUserInteractionEnabled = false
    }
}
