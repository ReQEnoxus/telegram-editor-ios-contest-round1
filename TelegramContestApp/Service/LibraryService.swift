//
//  LibraryService.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import Photos
import PhotosUI

protocol LibraryServiceProtocol {
    var currentPermissionStatus: PermissionStatus { get }
    func requestAccess(result: @escaping Consumer<PermissionStatus>)
    
    func fetchAssets() -> PHFetchResult<PHAsset>
    
    @discardableResult
    func fetchImage(from asset: PHAsset, targetSize: CGSize, completion: @escaping Consumer<LoadedAsset>) -> PHImageRequestID
    func cancelRequest(with id: PHImageRequestID)
    
    func save(image: UIImage, completion: @escaping Consumer<Bool>)
    func save(video at: URL, completion: @escaping Consumer<Bool>)
}

struct DefaultLibraryService: LibraryServiceProtocol {
    private let imageManager: PHImageManager
    
    init(imageManager: PHImageManager) {
        self.imageManager = imageManager
    }
    
    var currentPermissionStatus: PermissionStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite).permissionStatus
        } else {
            return PHPhotoLibrary.authorizationStatus().permissionStatus
        }
    }
    
    func fetchAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(PHAsset.creationDate), ascending: false)
        ]
        return PHAsset.fetchAssets(with: options)
    }
    
    @discardableResult
    func fetchImage(from asset: PHAsset, targetSize: CGSize, completion: @escaping Consumer<LoadedAsset>) -> PHImageRequestID {
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .fast
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        return imageManager.requestImage(
            for: asset,
               targetSize: targetSize,
               contentMode: .default,
               options: requestOptions
        ) { image, info in
            DispatchQueue.main.async {
                completion(
                    LoadedAsset(
                        image: image
                    )
                )
            }
        }
    }
    
    func cancelRequest(with id: PHImageRequestID) {
        imageManager.cancelImageRequest(id)
    }
    
    func requestAccess(result: @escaping Consumer<PermissionStatus>) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { authorization in
                DispatchQueue.main.async {
                    result(authorization.permissionStatus)
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { authorization in
                DispatchQueue.main.async {
                    result(authorization.permissionStatus)
                }
            }
        }
    }
    
    func save(image: UIImage, completion: @escaping Consumer<Bool>) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            print("!! error: \(error)")
            completion(success)
        }

    }
    
    func save(video at: URL, completion: @escaping Consumer<Bool>) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: at)
        } completionHandler: { success, error in
            print("!! error: \(error)")
            completion(success)
        }

    }
}

private extension PHAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
        case .authorized, .limited:
            return .allowed
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}
