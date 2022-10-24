//
//  PickerViewController.swift
//  TelegramContestApp
//
//  Created by Никита Афанасьев on 23.10.2022.
//

import UIKit
import PhotosUI

final class PickerViewController: UIViewController {
    private let libraryService: LibraryServiceProtocol
    private var assets: PHFetchResult<PHAsset>?
    private var permissionsView: RevealingView<PermissionsView>?
    private var mediaCollectionView: RevealingView<MediaCollectionView>?
    
    init(libraryService: LibraryServiceProtocol) {
        self.libraryService = libraryService
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
        let mediaCollectionView = RevealingView<MediaCollectionView>().forAutoLayout()
        self.mediaCollectionView = mediaCollectionView
        addConstrainedSubview(mediaCollectionView, bottomToSafeArea: false)
        mediaCollectionView.wrapped.collectionView.dataSource = self
        loadMediaData()
        mediaCollectionView.reveal { [weak self] in
            self?.permissionsView?.wrapped.stopAnimation()
        }
    }
}

extension PickerViewController: PermissionsViewDelegate {
    func didTapPermissionsButton() {
        requestAccess()
    }
}

extension PickerViewController: AssetCellDelegate {
    func didConfigure(with model: AssetCell.Model, size: CGSize, onLoad: Consumer<UIImage?>?) {
        libraryService.fetchImage(
            from: model.asset,
            targetSize: size
        ) { asset in
            onLoad?(asset.image)
        }
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
        cell.delegate = self
        cell.configure(with: AssetCell.Model(asset: asset))
        
        return cell
    }
}
