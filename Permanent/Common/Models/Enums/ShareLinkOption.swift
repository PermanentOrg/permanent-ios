//  
//  ShareLinkOption.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

enum ShareLinkOption {
    // Used when trying to retrieve an existing share link.
    case retrieve
    
    /// Used when creating a new share link.
    case create
    
    func endpoint(for viewModel: FileModel) -> RequestProtocol {
        switch self {
        case .retrieve: return ShareEndpoint.getLink(file: viewModel)
        case .create: return ShareEndpoint.generateShareLink(file: viewModel)
        }
    }
}
