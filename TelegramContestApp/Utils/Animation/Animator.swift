//
//  Animator.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 15.10.2022.
//

import Foundation
import QuartzCore
import UIKit

final class Animator {
    private var displayLink: CADisplayLink?
    
    private var currentProgress: CGFloat = .zero {
        didSet {
            if currentProgress > 1 {
                displayLink?.invalidate()
                // TODO: более надежное решение
                DispatchQueue.main.async {
                    self.completionBlock?()
                }
            }
        }
    }
    
    private var timingFunction: TimingFunction?
    private var progressBlock: Consumer<CGFloat>?
    private var completionBlock: Producer<Void>?
    private var duration: TimeInterval?
    
    func animateProgress(
        duration: TimeInterval,
        timingParameters: UICubicTimingParameters = UICubicTimingParameters(animationCurve: .linear),
        progressBlock: @escaping Consumer<CGFloat>,
        completion: Producer<Void>?
    ) {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(handleTick))
        timingFunction = TimingFunction(timingParameters: timingParameters, duration: duration)
        currentProgress = .zero
        completionBlock = completion
        self.progressBlock = progressBlock
        self.duration = duration
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func handleTick() {
        guard let displayLink = displayLink,
              let timingFunction = timingFunction,
              let progressBlock = progressBlock,
              let duration = duration
        else { return }
        currentProgress += displayLink.duration / duration
        let interpolatedProgress = timingFunction.progress(at: currentProgress)
        progressBlock(interpolatedProgress)
    }
}
