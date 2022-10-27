//
//  PickerViewController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import UIKit
import PhotosUI

final class PickerViewController: UIViewController {
    private enum Constants {
        static let maxPendingUpdatesCount = 30
    }
    
    private let libraryService: LibraryServiceProtocol
    private var assets: PHFetchResult<PHAsset>?
    private var permissionsView: RevealingView<PermissionsView>?
    private var mediaCollectionView: RevealingView<MediaCollectionView>?
    private var selectedIndexPath: IndexPath?
//    private var pendingUpdates: [IndexPath]
//    private var debouncer = Debouncer()
    
    init(libraryService: LibraryServiceProtocol) {
        self.libraryService = libraryService
//        self.pendingUpdates = []
//        pendingUpdates.reserveCapacity(Constants.maxPendingUpdatesCount)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawInitialView()
    }
    
    private func drawInitialView() {
        switch libraryService.currentPermissionStatus {
        case .allowed:
            drawCollection()
        case .denied, .notDetermined:
            let permissionsView = RevealingView<PermissionsView>().forAutoLayout()
            self.permissionsView = permissionsView
            addConstrainedSubview(permissionsView)
            permissionsView.wrapped.delegate = self
            permissionsView.wrapped.startAnimation()
            permissionsView.reveal()
        }
    }
    
    private func addConstrainedSubview(_ view: UIView, bottomToSafeArea: Bool = true) {
        self.view.addSubview(view)
        [
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomToSafeArea ? self.view.safeAreaLayoutGuide.bottomAnchor : self.view.bottomAnchor)
        ].activate()
    }
    
    private func loadMediaData() {
        assets = libraryService.fetchAssets()
        mediaCollectionView?.wrapped.collectionView.reloadData()
    }
    
    private func requestAccess() {
        switch libraryService.currentPermissionStatus {
        case .allowed:
            drawCollection()
        case .denied:
            navigateToSettings()
        case .notDetermined:
            libraryService.requestAccess { [weak self] status in
                if status == .allowed {
                    self?.drawCollection()
                }
            }
        }
    }
    
    private func navigateToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func drawCollection() {
        guard self.mediaCollectionView == nil else { return }
        let mediaCollectionView = RevealingView<MediaCollectionView>().forAutoLayout()
        self.mediaCollectionView = mediaCollectionView
        addConstrainedSubview(mediaCollectionView, bottomToSafeArea: false)
        mediaCollectionView.wrapped.collectionView.delegate = self
        mediaCollectionView.wrapped.collectionView.dataSource = self
        loadMediaData()
        mediaCollectionView.reveal { [weak self] in
            self?.permissionsView?.wrapped.stopAnimation()
        }
    }
    
    // update management
    
//    private func enqueueUpdate(for indexPath: IndexPath) {
//        pendingUpdates.append(indexPath)
//        if pendingUpdates.count == Constants.maxPendingUpdatesCount {
//            executePendingUpdates()
//        } else {
//            debouncer.debounce { [weak self] in
//                self?.executePendingUpdates()
//            }
//        }
//    }
//
//    private func executePendingUpdates() {
//        print("!! executing update for \(pendingUpdates)")
//        mediaCollectionView?.wrapped.collectionView.reloadItems(at: pendingUpdates)
//        pendingUpdates.removeAll(keepingCapacity: true)
//    }
}

extension PickerViewController: PermissionsViewDelegate {
    func didTapPermissionsButton() {
        requestAccess()
    }
}

extension PickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let asset = assets?.object(at: indexPath.item) else {
            assertionFailure("No asset for indexPath = \(indexPath)")
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueCell(
            of: AssetCell.self,
            for: indexPath
        )
        
        if asset.localIdentifier != cell.assetId {
            
            cell.assetId = asset.localIdentifier
            
            if let cancelId = cell.cancelId {
                libraryService.cancelRequest(with: cancelId)
            }
            
            cell.configure(
                with: AssetCell.Model(
                    duration: asset.mediaType == .video ? asset.formattedDuration : nil,
                    pixelHeight: asset.pixelHeight,
                    pixelWidth: asset.pixelWidth
                )
            )
            cell.updateImage(with: nil)
            cell.cancelId = libraryService.fetchImage(
                from: asset,
                targetSize: CGSize(
                    width: cell.bounds.width * UIScreen.main.scale.doubled,
                    height: cell.bounds.height * UIScreen.main.scale.doubled
                ),
                completion: { loaded in
                    guard cell.assetId == asset.localIdentifier else { return }
                    cell.updateImage(with: loaded.image)
                }
            )
        }
        
        return cell
    }    
}

extension PickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let asset = assets?.object(at: indexPath.item) else { return }
        selectedIndexPath = indexPath
        let editor = EditorModuleAssembly().assemble(asset: asset)
        editor.transitionController.fromDelegate = self
        editor.transitionController.toDelegate = editor
        present(editor, animated: true)
    }
}

extension PickerViewController: TransitionDelegate {
    func reference() -> ViewReference? {
        guard let selectedIndexPath = selectedIndexPath,
              let cell = mediaCollectionView?.wrapped.collectionView.cellForItem(at: selectedIndexPath) as? AssetCell,
              let image = cell.imageView.image else { return nil }
        
        return ViewReference(view: cell, image: image, frame: view.convert(cell.bounds, from: cell))
    }
}
