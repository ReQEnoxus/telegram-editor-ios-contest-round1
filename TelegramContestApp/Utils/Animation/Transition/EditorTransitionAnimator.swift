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
              let fromReference = fromDelegate?.reference()else { return }
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toController)
        containerView.addSubview(toController.view)
        containerView.addSubview(fromController.view)
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
        let targetRect = targetRect(for: fromReference.image, in: fromController.view)
        
        if containerView.safeAreaInsets.top != .zero {
            let containerSafeAreaMask = UIView(
                frame: CGRect(
                    origin: containerView.frame.origin,
                    size: CGSize(
                        width: containerView.frame.width,
                        height: containerView.safeAreaInsets.top
                    )
                )
            )
            containerSafeAreaMask.backgroundColor = .black
            containerView.addSubview(containerSafeAreaMask)
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: .zero,
            usingSpringWithDamping: Constants.springDamping,
            initialSpringVelocity: Constants.initialSpringVelocity,
            options: []
        ) {
            self.transitionImageView?.frame = targetRect
            fromController.view.alpha = .zero
            toController.view.alpha = .one
        } completion: { _ in
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
            let toReference = toDelegate?.reference() else { return }
        
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toController)
        
        containerView.addSubview(toController.view)
        toController.view.frame = finalFrame
        toController.view.isHidden = false
        toController.view.alpha = .zero
        toReference.view.isHidden = true
        containerView.addSubview(fromController.view)
        fromController.view.alpha = .one
        
        if self.transitionImageView == nil {
            let imageView = UIImageView(image: fromReference.image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = targetRect(for: fromReference.image, in: fromController.view)
            self.transitionImageView = imageView
            containerView.addSubview(imageView)
        }
        
        let targetRect = toReference.frame
        
        if containerView.safeAreaInsets.top != .zero {
            let containerSafeAreaMask = UIView(
                frame: CGRect(
                    origin: containerView.frame.origin,
                    size: CGSize(
                        width: containerView.frame.width,
                        height: containerView.safeAreaInsets.top
                    )
                )
            )
            containerSafeAreaMask.backgroundColor = .black
            containerView.addSubview(containerSafeAreaMask)
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
            self.transitionImageView?.removeFromSuperview()
            self.transitionImageView = nil
            toController.view.isHidden = false
            toReference.view.isHidden = false

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func targetRect(for image: UIImage, in view: UIView) -> CGRect {
        // TODO: Horizontal
        let frame = view.frame.inset(by: view.safeAreaInsets)
        return AVMakeRect(
            aspectRatio: image.size,
            insideRect: CGRect(
                x: frame.origin.x,
                y: frame.origin.y + .xxxl.half,
                width: frame.width,
                height: frame.height - .xxxl.half - .xxxl
            )
        )
//        let widthFactor = view.frame.width / image.size.width
//        let targetHeight = min(image.size.height * widthFactor, frame.height - .xxxl.doubled)
//        return CGRect(
//            x: .zero,
//            y: (frame.height - targetHeight).half - .xl + view.safeAreaInsets.top,
//            width: view.frame.width,
//            height: targetHeight
//        )
    }
}
