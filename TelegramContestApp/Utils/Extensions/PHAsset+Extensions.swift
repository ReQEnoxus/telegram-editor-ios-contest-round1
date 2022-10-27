//
//  PHAsset+Extensions.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import Photos

fileprivate let formatter = DateComponentsFormatter()

extension PHAsset {
    var formattedDuration: String {
        return formatter.string(from: duration) ?? ""
    }
}
