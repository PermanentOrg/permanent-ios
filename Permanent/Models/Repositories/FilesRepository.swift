//
//  FilesRepository.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 10.10.2022.
//

import Foundation

class FilesRepository {
    let remoteDataSource: FilesRemoteDataSource
    
    init(remoteDataSource: FilesRemoteDataSource = FilesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func folderContent(folderVO: FolderVOData, completion: @escaping (([FileViewModel], Error?) -> Void)) {
        remoteDataSource.folderContent(folderVO: folderVO, completion: completion)
    }
    
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileViewModel?, Error?) -> Void)) {
        remoteDataSource.createNewFolder(name: name, folderLinkId: folderLinkId, completion: completion)
    }
}
