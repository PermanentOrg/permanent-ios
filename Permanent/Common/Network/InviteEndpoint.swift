//
//  InviteEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

enum InviteEndpoint {
    
    case getMyInvites
    
    case sendInvite(name: String, email: String)
    
    case resendInvite(id: Int)
    
    case revokeInvite(id: Int)
}

extension InviteEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getMyInvites:
            return "/invite/getMyInvites"
        case .sendInvite:
            return "/invite/inviteSend"
        case .resendInvite:
            return "/invite/inviteResend"
        case .revokeInvite:
            return "/invite/revoke"
            
        }
    }
    
    var method: RequestMethod { .post }
    
    var parameters: RequestParameters? { nil }
        
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .getMyInvites:
            
            let emptyPayload = NoDataModel()
            let requestVO = APIPayload.make(fromData: [emptyPayload])
            
            return try? APIPayload<NoDataModel>.encoder.encode(requestVO)
            
        case .sendInvite(let name, let email):
            let invitePayload = InviteVOPayload(name: name, email: email)
            let requestVO = APIPayload.make(fromData: [invitePayload])
            
            return try? APIPayload<InviteVOPayload>.encoder.encode(requestVO)
            
        case .resendInvite(let id),
             .revokeInvite(let id):
            
            let invitePayload = InviteVOPayload(id: id, name: nil, email: nil)
            let requestVO = APIPayload.make(fromData: [invitePayload])
            
            return try? APIPayload<InviteVOPayload>.encoder.encode(requestVO)
        }
    }
    
    var customURL: String? {
        nil
    }
}
