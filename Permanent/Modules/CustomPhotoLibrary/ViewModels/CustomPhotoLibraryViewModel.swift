//
//  CustomPhotoLibraryViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.12.2023.

import Foundation
import PhotosUI

class CustomPhotoLibraryViewModel: ObservableObject {
    @Published var hasUpdates: Bool = false
    
    @Published var selectedPhotos: Set<PHAsset> = []
    @Published var imagesInPhotos: [PHAsset] = []
    @Published var imagesInAlbums: [PHAsset] = []
    @Published var selectedSegment = 0
}
