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
    var widthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(aspectContainer)
        widthConstraint = aspectContainer.widthAnchor.constraint(equalToConstant: 50)
        heightConstraint = aspectContainer.heightAnchor.constraint(equalToConstant: 50)
        [
            aspectContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            aspectContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            widthConstraint,
            heightConstraint
        ].compactMap { $0 }.activate()
        aspectContainer.image = UIImage(named: "mnt")
        
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
