//
//  Debouncer.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 26.10.2022.
//

import Foundation

struct Debouncer {
    
    private let queue = DispatchQueue.main
    private var workItem = DispatchWorkItem(block: {})
    private var interval: DispatchTimeInterval
    
    init(timeInterval: DispatchTimeInterval = .milliseconds(30)) {
        self.interval = timeInterval
    }
    
    mutating func debounce(_ action: @escaping (() -> Void)) {
        workItem.cancel()
        workItem = DispatchWorkItem(block: { action() })
        queue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }
}
