//
//  EditorModuleAssembly.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 24.10.2022.
//

import Foundation
import Photos
import UIKit

struct EditorModuleAssembly {
    func assemble(asset: PHAsset) -> EditorViewController {
        let service = DefaultLibraryService(
            imageManager: imageManager
        )
        let view = EditorViewController(asset: asset, service: service)
        return view
    }
}
