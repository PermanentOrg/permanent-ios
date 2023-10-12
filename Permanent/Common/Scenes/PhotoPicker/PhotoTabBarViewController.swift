//
//  FileDetailsBaseCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Rusu on 25.08.2021.
//

import UIKit
import Photos

protocol PhotoPickerViewControllerDelegate: AnyObject {
    func photoTabBarViewControllerDidPickAssets(_ vc: PhotoTabBarViewController?, assets: [PHAsset])
}

class PhotoTabBarViewController: UITabBarController {
    weak var pickerDelegate: PhotoPickerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.tintColor = .primary
        var tabViewControllers: [UIViewController] = [
            UIStoryboard(name: "PhotoPicker", bundle: nil).instantiateViewController(withIdentifier: "assets"),
            UIStoryboard(name: "PhotoPicker", bundle: nil).instantiateViewController(withIdentifier: "albums")
        ]
        
        let assetFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
        if let assetCollection = assetFetchResult.firstObject {
            let favoritesVC = UIStoryboard(name: "PhotoPicker", bundle: nil).instantiateViewController(withIdentifier: "assets")
            favoritesVC.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star.fill"), selectedImage: nil)
            let assetGridVC = (favoritesVC as! UINavigationController).viewControllers.first as! AssetGridViewController
            assetGridVC.assetCollection = assetCollection
            assetGridVC.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
            assetGridVC.title = "Favorites".localized()
            
            tabViewControllers.insert(favoritesVC, at: 1)
        }
        
        setViewControllers(tabViewControllers, animated: false)
    }
}

extension PhotoTabBarViewController: AssetPickerDelegate {
    func assetGridViewControllerDidPickAssets(_ vc: AssetGridViewController?, assets: [PHAsset]) {
        if presentedViewController != nil {
            dismiss(animated: false) {
                self.dismiss(animated: true) {
                    self.pickerDelegate?.photoTabBarViewControllerDidPickAssets(self, assets: assets)
                }
            }
        } else {
            dismiss(animated: true) {
                self.pickerDelegate?.photoTabBarViewControllerDidPickAssets(self, assets: assets)
            }
        }
    }
}
