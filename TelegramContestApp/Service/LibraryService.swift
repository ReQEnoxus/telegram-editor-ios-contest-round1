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
    func fetchImage(from asset: PHAsset, targetSize: CGSize, completion: @escaping Consumer<LoadedAsset>)
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
    
    func fetchImage(from asset: PHAsset, targetSize: CGSize, completion: @escaping Consumer<LoadedAsset>) {
        let requestOptions = PHImageRequestOptions()
        imageManager.requestImage(
            for: asset,
               targetSize: targetSize,
               contentMode: .default,
               options: requestOptions
        ) { image, info in
            DispatchQueue.main.async {
                completion(LoadedAsset(image: image))
            }
        }
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