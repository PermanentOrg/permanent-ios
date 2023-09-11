//
//  FilesRepository.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 10.10.2022.
//

import Foundation

class FilesRepository {
    let remoteDataSource: FilesRemoteDataSourceInterface
    
    init(remoteDataSource: FilesRemoteDataSourceInterface = FilesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func folderContent(archiveNo: String, folderLinkId: Int, byMe: Bool = false, completion: @escaping (([FileModel], Error?) -> Void)) {
        remoteDataSource.folderContent(archiveNo: archiveNo, folderLinkId: folderLinkId, byMe: byMe, completion: completion)
    }
    
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileModel?, Error?) -> Void)) {
        remoteDataSource.createNewFolder(name: name, folderLinkId: folderLinkId, completion: completion)
    }
    
    func getPrivateRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        remoteDataSource.getPrivateRoot(completion: completion)
    }
    
    func getSharedRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        remoteDataSource.getSharedRoot(completion: completion)
    }
    
    func getPublicRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        remoteDataSource.getPublicRoot(completion: completion)
    }
}
