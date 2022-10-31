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
    func renderVideo(_ videoAsset: PHAsset, refImage: UIImage, canvas: CALayer, completion: @escaping Consumer<URL>)
}

struct DefaultRenderService: RenderServiceProtocol {
    func renderVideo(_ videoAsset: PHAsset, refImage: UIImage, canvas: CALayer, completion: @escaping Consumer<URL>) {
        DispatchQueue.global(qos: .userInitiated).async {
            let layerImage = renderLayer(canvas, backgroundImage: refImage)
            
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            imageManager.requestAVAsset(forVideo: videoAsset, options: options) { avasset, mix, _ in
                guard let avasset = avasset else {
                    print("!! fail to get avasset")
                    return
                }
                
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let outputPath = documentsURL?.appendingPathComponent("\(UUID().uuidString).mov")

                let comp = AVMutableComposition()
                comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                let clipVideoTrack = avasset.tracks(withMediaType: .video)[0]
                let imageLayer = CALayer()
                imageLayer.contents = layerImage.cgImage
                imageLayer.frame = CGRect(origin: .zero, size: layerImage.size)
                
                let videoSize = clipVideoTrack.naturalSize
                let parentlayer = CALayer()
                let videoLayer = CALayer()
                
                parentlayer.frame = CGRect(origin: .zero, size: videoSize)
                videoLayer.frame = CGRect(origin: .zero, size: videoSize)
                parentlayer.addSublayer(videoLayer)
                parentlayer.addSublayer(imageLayer)
                
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = videoSize
                videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
                videoComposition.renderScale = 1.0
                videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentlayer)
                
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange.init(start: .zero, end: avasset.duration)
                let clipInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: clipVideoTrack)
                clipInstruction.setTransform(CGAffineTransform(rotationAngle: .pi/2), at: .zero)
                instruction.layerInstructions = [clipInstruction]
                videoComposition.instructions = [instruction]

                let exporter = AVAssetExportSession.init(asset: avasset, presetName: AVAssetExportPresetHighestQuality)
                exporter?.outputFileType = .mov
                exporter?.outputURL = outputPath
                exporter?.videoComposition = videoComposition
                exporter?.exportAsynchronously {
                    if let outputPath = outputPath {
                        DispatchQueue.main.async {
                            completion(outputPath)
                        }
                    }
                }
            }
        }
    }
    
    func renderImage(_ backgroundImage: UIImage, canvas: CALayer, completion: @escaping Consumer<UIImage>) {
        DispatchQueue.global(qos: .userInitiated).async {
            let layerImage = renderLayer(canvas, backgroundImage: backgroundImage)
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
    
    private func renderLayer(_ layer: CALayer, backgroundImage: UIImage) -> UIImage {
        let scale = backgroundImage.size.width / layer.frame.size.width
        UIGraphicsBeginImageContextWithOptions(backgroundImage.size, false, .zero)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            context.scaleBy(x: scale, y: scale)
            layer.render(in: context)
        }
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
