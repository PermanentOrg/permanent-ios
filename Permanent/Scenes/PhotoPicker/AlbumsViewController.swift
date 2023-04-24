//
//  AlbumsViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 25.08.2021.
//

import UIKit
import Photos

private let reuseIdentifier = "AlbumCollectionViewCell"

class AlbumsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    enum Section: Int {
        case userCollections = 0
        
        static let count = 1
    }
    
    var userCollections: PHFetchResult<PHCollection>!
    
    fileprivate let imageManager = PHCachingImageManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a PHFetchResult object for each section in the table view.
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        PHPhotoLibrary.shared().register(self)
        
        styleNavBar()
    }
    
    func styleNavBar() {
        navigationController?.navigationBar.tintColor = .white
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .darkBlue
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: Text.style14.font
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
    }
    
    /// - Tag: UnregisterChangeObserver
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = (segue.destination as? UINavigationController)?.topViewController as? AssetGridViewController
        else { return }
        guard let cell = sender as? AlbumCollectionViewCell else { return }
        
        destination.title = cell.titleLabel?.text
        
        // Fetch the asset collection for the selected row.
        let indexPath = collectionView.indexPath(for: cell)!
        let collection: PHCollection
        switch Section(rawValue: indexPath.section)! {
        case .userCollections:
            collection = userCollections.object(at: indexPath.row)
        }
        
        // configure the view controller with the asset collection
        guard let assetCollection = collection as? PHAssetCollection
        else { return }
        destination.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        destination.assetCollection = assetCollection
        
        destination.delegate = tabBarController as? PhotoTabBarViewController
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return Section.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .userCollections: return userCollections.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCollectionViewCell
        
        let collection: PHCollection?
        switch Section(rawValue: indexPath.section) {
        case .userCollections:
            collection = userCollections.object(at: indexPath.row)
            
        case .none:
            collection = nil
        }
        
        cell.titleLabel.text = collection?.localizedTitle
        
        if let assetCollection = collection as? PHAssetCollection {
            let opts = PHFetchOptions()
            opts.fetchLimit = 1
            let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: opts)
            if let asset = fetchResult.firstObject {
                imageManager.requestImage(for: asset, targetSize: CGSize(width: 80, height: 80), contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                    cell.imageView.image = image
                })
            }
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let edgeSize = (view.bounds.width - 30) / 2
        return CGSize(width: edgeSize, height: edgeSize)
    }
}

// MARK: PHPhotoLibraryChangeObserver

extension AlbumsViewController: PHPhotoLibraryChangeObserver {
    /// - Tag: RespondToChanges
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may originate from a background queue.
        // Re-dispatch to the main queue before acting on the change,
        // so you can update the UI.
        DispatchQueue.main.sync {
            // Update the cached fetch results, and reload the table sections to match.
            if let changeDetails = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetails.fetchResultAfterChanges
                collectionView.reloadSections(IndexSet(integer: Section.userCollections.rawValue))
            }
        }
    }
}
