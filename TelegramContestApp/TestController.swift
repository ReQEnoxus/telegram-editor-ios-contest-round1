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
    private let penView = PenToolView().forAutoLayout()
    private let legacyColorPicker = LegacyColorPicker().forAutoLayout()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
//        view.addSubview(morphingSlider)
//        view.addSubview(lottieButton)
//        view.addSubview(penView)
        lottieButton.setMode(.close, animated: false)
        morphingSlider.configure(with: MorphingSlider.Model(sliderValue: 1, segmentedControlModel: SegmentedControl.Model(items: ["Draw", "Text"], cornerRadius: 16)))
        view.addSubview(legacyColorPicker)
        [
            legacyColorPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            legacyColorPicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            legacyColorPicker.heightAnchor.constraint(equalToConstant: 240),
        ].activate()
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
//            penView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            penView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            morphingSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            morphingSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            morphingSlider.widthAnchor.constraint(equalToConstant: 250)
        ].compactMap { $0 }.activate()
//        aspectContainer.image = UIImage(named: "mnt")
        penView.color = UIColor.red
        penView.width = 16
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.widthConstraint?.constant = self.view.frame.width
//            self.heightConstraint?.constant = 200
//            
//            UIView.animate(withDuration: 0.6) {
//                self.view.layoutIfNeeded()
//            }
//        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
////            self.morphingSlider.setMode(.slider)
//            self.penView.color = UIColor.yellow
//            self.penView.width = 5
////            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
////                self.morphingSlider.setMode(.segmentedControl)
////            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                self.penView.color = UIColor.green
//                self.penView.width = 24
//    //            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//    //                self.morphingSlider.setMode(.segmentedControl)
//    //            }
//            }
//        }
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
