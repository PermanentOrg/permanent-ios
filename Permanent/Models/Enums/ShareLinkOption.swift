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
    
    /// Used for accept share request
    case acceptRequest
    
    /// Used for restricting a share request
    case denyRequest
    
    func endpoint(for viewModel: FileViewModel, and csrf: String) -> RequestProtocol {
        switch self {
        case .retrieve: return ShareEndpoint.getLink(file: viewModel, csrf: csrf)
        case .create: return ShareEndpoint.generateShareLink(file: viewModel, csrf: csrf)
        case .acceptRequest: return ShareEndpoint.updateShareRequest(file: viewModel, csrf: csrf)
        case .denyRequest: return ShareEndpoint.deleteShareRequest(file: viewModel, csrf: csrf)
        }
    }
}
