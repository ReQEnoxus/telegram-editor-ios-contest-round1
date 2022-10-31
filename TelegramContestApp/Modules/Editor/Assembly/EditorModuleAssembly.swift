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
    func assemble(asset: PHAsset, initialImage: UIImage?) -> EditorViewController {
        let service = DefaultLibraryService(
            imageManager: imageManager
        )
        let renderService = DefaultRenderService()
        let view = EditorViewController(
            asset: asset,
            service: service,
            renderService: renderService,
            initialImage: initialImage
        )
        return view
    }
}
