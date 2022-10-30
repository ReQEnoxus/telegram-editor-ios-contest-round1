//
//  RenderService.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 29.10.2022.
//

import Foundation
import UIKit
import Photos

protocol RenderServiceProtocol {
    func renderImage(_ backgroundImage: UIImage, canvas: CALayer, completion: @escaping Consumer<UIImage>)
    func renderVideo(_ videoAsset: PHAsset, canvas: CALayer, completion: @escaping Consumer<URL>)
}

struct DefaultRenderService: RenderServiceProtocol {
    func renderVideo(_ videoAsset: PHAsset, canvas: CALayer, completion: @escaping Consumer<URL>) {
        
    }
    
    func renderImage(_ backgroundImage: UIImage, canvas: CALayer, completion: @escaping Consumer<UIImage>) {
        DispatchQueue.global(qos: .userInitiated).async {
            let scale = backgroundImage.size.width / canvas.frame.size.width
            UIGraphicsBeginImageContextWithOptions(backgroundImage.size, false, .zero)
            if let context = UIGraphicsGetCurrentContext() {
                context.scaleBy(x: scale, y: scale)
                canvas.render(in: context)
            }
            let layerImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            UIGraphicsBeginImageContextWithOptions(backgroundImage.size, true, .zero)
            defer { UIGraphicsEndImageContext() }
            if let _ = UIGraphicsGetCurrentContext() {
                backgroundImage.draw(at: .zero)
                layerImage.draw(at: .zero)
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()!

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
