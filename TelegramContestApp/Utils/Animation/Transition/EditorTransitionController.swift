//
//  EditorTransitionController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 25.10.2022.
//

import Foundation
import UIKit

final class EditorTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    let animator: EditorTransitionAnimator
    
    weak var fromDelegate: TransitionDelegate?
    weak var toDelegate: TransitionDelegate?
    
    override init() {
        animator = EditorTransitionAnimator()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.currentDirection = .transitionIn
        animator.fromDelegate = fromDelegate
        animator.toDelegate = toDelegate
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.currentDirection = .transitionOut
        animator.fromDelegate = toDelegate
        animator.toDelegate = fromDelegate
        return animator
    }
}
