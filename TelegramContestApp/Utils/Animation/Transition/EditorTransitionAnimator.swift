//
//  EditorTransitionAnimator.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 25.10.2022.
//

import Foundation
import UIKit
import AVFoundation

protocol TransitionDelegate: AnyObject {
    func reference() -> ViewReference?
    func referenceFrame(for image: UIImage, in rect: CGRect) -> CGRect?
}

extension TransitionDelegate {
    func referenceFrame(for image: UIImage, in rect: CGRect) -> CGRect? { return nil }
}

final class EditorTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private enum Constants {
        static let springDamping: CGFloat = 0.8
        static let initialSpringVelocity: CGFloat = 2
    }
    enum TransitionDirection {
        case transitionIn
        case transitionOut
    }
    
    weak var fromDelegate: TransitionDelegate?
    weak var toDelegate: TransitionDelegate?
    
    var currentDirection: TransitionDirection = .transitionIn
    
    private var transitionImageView: UIImageView?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch currentDirection {
        case .transitionIn:
            return Durations.double
        case .transitionOut:
            return Durations.double
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch currentDirection {
        case .transitionIn:
            animateTransitionIn(using: transitionContext)
        case .transitionOut:
            animateTransitionOut(using: transitionContext)
        }
    }
    
    private func animateTransitionIn(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: .from),
              let toController = transitionContext.viewController(forKey: .to),
              let fromReference = fromDelegate?.reference(),
              let targetImageRect = toDelegate?.referenceFrame(for: fromReference.image, in: fromController.view.frame.inset(by: fromController.view.safeAreaInsets)) else { return }
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toController)
        containerView.addSubview(toController.view)
        toController.view.alpha = .zero
        
        if transitionImageView == nil {
            let imageView = UIImageView(image: fromReference.image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = fromReference.frame
            transitionImageView = imageView
            containerView.addSubview(imageView)
        }
        
        toController.view.frame = finalFrame
        
        var containerSafeAreaMask: UIView?
        if containerView.safeAreaInsets.top != .zero {
            let mask = UIView(
                frame: CGRect(
                    origin: containerView.frame.origin,
                    size: CGSize(
                        width: containerView.frame.width,
                        height: containerView.safeAreaInsets.top
                    )
                )
            )
            mask.backgroundColor = .black
            containerView.addSubview(mask)
            containerSafeAreaMask = mask
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: .zero,
            usingSpringWithDamping: Constants.springDamping,
            initialSpringVelocity: Constants.initialSpringVelocity,
            options: []
        ) {
            self.transitionImageView?.frame = targetImageRect
            fromController.view.alpha = .zero
            toController.view.alpha = .one
        } completion: { _ in
            containerSafeAreaMask?.removeFromSuperview()
            self.transitionImageView?.removeFromSuperview()
            self.transitionImageView = nil
            toController.view.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func animateTransitionOut(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: .to),
            let fromController = transitionContext.viewController(forKey: .from),
            let fromReference = fromDelegate?.reference(),
            let toReference = toDelegate?.reference(),
              let targetImageRect = fromDelegate?.referenceFrame(for: fromReference.image, in: fromController.view.frame.inset(by: fromController.view.safeAreaInsets)) else { return }
        
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toController)
        
        containerView.addSubview(fromController.view)
        toController.view.frame = finalFrame
        toController.view.isHidden = false
        toController.view.alpha = .zero
        toReference.view.isHidden = true
        fromController.view.alpha = .one
        
        if self.transitionImageView == nil {
            let imageView = UIImageView(image: fromReference.image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = targetImageRect
            self.transitionImageView = imageView
            containerView.addSubview(imageView)
        }
        
        let targetRect = toReference.frame
        
        var containerSafeAreaMask: UIView?
        if containerView.safeAreaInsets.top != .zero {
            let mask = UIView(
                frame: CGRect(
                    origin: containerView.frame.origin,
                    size: CGSize(
                        width: containerView.frame.width,
                        height: containerView.safeAreaInsets.top
                    )
                )
            )
            mask.backgroundColor = .black
            containerView.addSubview(mask)
            containerSafeAreaMask = mask
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: .zero,
            usingSpringWithDamping: Constants.springDamping,
            initialSpringVelocity: Constants.initialSpringVelocity,
            options: []
        ) {
            self.transitionImageView?.frame = targetRect
            toController.view.alpha = .one
            fromController.view.alpha = .zero
        } completion: { _ in
            containerSafeAreaMask?.removeFromSuperview()
            self.transitionImageView?.removeFromSuperview()
            self.transitionImageView = nil
            toController.view.isHidden = false
            toReference.view.isHidden = false

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
