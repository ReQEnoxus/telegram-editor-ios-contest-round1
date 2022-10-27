//
//  PickerModuleAssembly.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import Foundation
import UIKit
import Photos

struct PickerModuleAssembly {
    func assemble() -> UIViewController {
        let service = DefaultLibraryService(
            imageManager: imageManager
        )
        let view = PickerViewController(libraryService: service)
        
        return view
    }
}
