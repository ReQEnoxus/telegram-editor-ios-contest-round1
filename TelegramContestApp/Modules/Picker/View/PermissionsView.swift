//
//  PermissionsView.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import UIKit
import Lottie

protocol PermissionsViewDelegate: AnyObject {
    func didTapPermissionsButton()
}

final class PermissionsView: UIView {
    private enum Constants {
        static let labelFontSize: CGFloat = 18
        static let buttonFontSize: CGFloat = 16
        
        static let animationViewSize: CGSize = CGSize(width: 150, height: 150)
    }
    
    weak var delegate: PermissionsViewDelegate?
    
    private let permissionsLabel: UILabel = UILabel().forAutoLayout()
    private let sweepingButton: SweepingButton = SweepingButton(type: .system).forAutoLayout()
    private let animationView: LottieAnimationView = LottieAnimationView().forAutoLayout()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func startAnimation() {
        animationView.play(completion: nil)
    }
    
    func stopAnimation() {
        animationView.stop()
    }
    
    private func commonInit() {
        backgroundColor = .black
        
        setupAnimationView()
        setupSweepingButton()
        setupPermissionsLabel()
        
        addSubviews()
        makeConstraints()
    }
    
    private func addSubviews() {
        addSubview(permissionsLabel)
        addSubview(sweepingButton)
        addSubview(animationView)
    }
    
    private func makeConstraints() {
        let centeringLayoutGuide = UILayoutGuide()
        addLayoutGuide(centeringLayoutGuide)
        
        [
            centeringLayoutGuide.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            
            animationView.topAnchor.constraint(equalTo: centeringLayoutGuide.topAnchor),
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            animationView.widthAnchor.constraint(equalToConstant: Constants.animationViewSize.width),
            animationView.heightAnchor.constraint(equalToConstant: Constants.animationViewSize.height),
            
            permissionsLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: .s),
            permissionsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            sweepingButton.topAnchor.constraint(equalTo: permissionsLabel.bottomAnchor, constant: .m),
            sweepingButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .s),
            sweepingButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.s),
            
            sweepingButton.bottomAnchor.constraint(equalTo: centeringLayoutGuide.bottomAnchor)
        ].activate()
    }
    
    private func setupAnimationView() {
        var animation: LottieAnimation?
        if let animationUrl = Bundle.main.url(forResource: "duck", withExtension: "json"),
           let animationData = try? Data(contentsOf: animationUrl) {
            animation = try? .from(data: animationData)
        }
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
    }
    
    private func setupPermissionsLabel() {
        permissionsLabel.textColor = .white
        permissionsLabel.text = L10n.Screens.Permissions.accessPhotosAndVideos
        permissionsLabel.font = .systemFont(ofSize: Constants.labelFontSize, weight: .medium)
    }
    
    private func setupSweepingButton() {
        sweepingButton.setTitleColor(.white, for: .normal)
        sweepingButton.backgroundColor = .systemBlue
        sweepingButton.titleLabel?.font = .systemFont(ofSize: Constants.buttonFontSize, weight: .medium)
        sweepingButton.setTitle(L10n.Screens.Permissions.accessButtonTitle, for: .normal)
        sweepingButton.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }
    
    @objc private func handleButtonTap() {
        delegate?.didTapPermissionsButton()
    }
}
