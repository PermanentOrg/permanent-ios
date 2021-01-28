//
//  InviteEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

enum InviteEndpoint {
    
    case getMyInvites
    
    case sendInvite(name: String, email: String, csrf: String)
    
    case resendInvite(id: Int, csrf: String)
    
    case revokeInvite(id: Int, csrf: String)
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
    
    var headers: RequestHeaders? { nil }
    
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
            let requestVO = APIPayload.make(fromData: [emptyPayload], csrf: nil)
            
            return try? APIPayload<NoDataModel>.encoder.encode(requestVO)
            
        case .sendInvite(let name, let email, let csrf):
            let invitePayload = InviteVOPayload(name: name, email: email)
            let requestVO = APIPayload.make(fromData: [invitePayload], csrf: csrf)
            
            return try? APIPayload<InviteVOPayload>.encoder.encode(requestVO)
            
        case .resendInvite(let id, let csrf),
             .revokeInvite(let id, let csrf):
            
            let invitePayload = InviteVOPayload(id: id, name: nil, email: csrf)
            let requestVO = APIPayload.make(fromData: [invitePayload], csrf: csrf)
            
            return try? APIPayload<InviteVOPayload>.encoder.encode(requestVO)
        }
    }
    
    var customURL: String? {
        nil
    }
}
