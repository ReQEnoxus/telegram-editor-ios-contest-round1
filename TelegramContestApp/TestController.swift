//
//  TestController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import UIKit

final class TestController: UIViewController {
    private let aspectContainer: WidthAspectContainer = WidthAspectContainer().forAutoLayout()
    private let slider = Slider().forAutoLayout()
    var widthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    private let lottieButton = LottieCloseButton().forAutoLayout()
    private let morphingSlider = MorphingSlider().forAutoLayout()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(morphingSlider)
        morphingSlider.configure(with: MorphingSlider.Model(sliderValue: 1, segmentedControlModel: SegmentedControl.Model(items: ["Draw", "Text"], cornerRadius: 16)))
//        slider.minimumValue = 0.33
//        slider.maximumValue = 1.5
//        slider.value = 1
//        slider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
//        widthConstraint = aspectContainer.widthAnchor.constraint(equalToConstant: 50)
//        heightConstraint = aspectContainer.heightAnchor.constraint(equalToConstant: 50)
        [
//            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            slider.widthAnchor.constraint(equalToConstant: 200)
//            lottieButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            lottieButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            lottieButton.widthAnchor.constraint(equalToConstant: .l),
//            lottieButton.heightAnchor.constraint(equalToConstant: .l)
            morphingSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            morphingSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            morphingSlider.widthAnchor.constraint(equalToConstant: 250)
        ].compactMap { $0 }.activate()
//        aspectContainer.image = UIImage(named: "mnt")
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.widthConstraint?.constant = self.view.frame.width
//            self.heightConstraint?.constant = 200
//            
//            UIView.animate(withDuration: 0.6) {
//                self.view.layoutIfNeeded()
//            }
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.morphingSlider.setMode(.slider)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                self.morphingSlider.setMode(.segmentedControl)
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.morphingSlider.setMode(.segmentedControl)
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    //                self.morphingSlider.setMode(.segmentedControl)
    //            }
            }
        }
    }
    
    @objc private func tap() {
        lottieButton.setMode(nextMode(for: lottieButton.mode), animated: true)
    }
    
    private func nextMode(for mode: LottieCloseButton.Mode) -> LottieCloseButton.Mode {
        switch mode {
        case .close:
            return .back
        case .back:
            return .close
        }
    }
}
