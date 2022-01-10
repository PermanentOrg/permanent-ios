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
    }

}

extension PhotoTabBarViewController: AssetPickerDelegate {
    func assetGridViewControllerDidPickAssets(_ vc: AssetGridViewController?, assets: [PHAsset]) {
        pickerDelegate?.photoTabBarViewControllerDidPickAssets(self, assets: assets)
        
        if presentedViewController != nil {
            dismiss(animated: false) {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}
