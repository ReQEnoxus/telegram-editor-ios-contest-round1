//
//  EditorNavigationController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 28.10.2022.
//

import Foundation
import UIKit

final class EditorNavigationController: UINavigationController {
    let transitionController = EditorTransitionController()
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        modalPresentationStyle = .overCurrentContext
        transitioningDelegate = transitionController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
