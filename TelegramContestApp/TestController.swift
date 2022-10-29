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
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(slider)
        slider.minimumValue = 0.33
        slider.maximumValue = 1.5
        slider.value = 1
        slider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
//        widthConstraint = aspectContainer.widthAnchor.constraint(equalToConstant: 50)
//        heightConstraint = aspectContainer.heightAnchor.constraint(equalToConstant: 50)
        [
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.widthAnchor.constraint(equalToConstant: 200)
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
    }
}
