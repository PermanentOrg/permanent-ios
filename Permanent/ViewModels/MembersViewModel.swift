//  
//  MembersViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

typealias AddMemberParams = (accountId: Int?, email: String, role: String)

class MembersViewModel: ViewModelInterface {
    fileprivate var members: [Account] = []
    fileprivate var sortedMembers: [Account] = []
    fileprivate var memberSections: [AccessRole: [Account]] = [:]
    
    var currentArchive: ArchiveVOData? { return try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive) }
    var archivePermissions: [Permission] {
        guard let accessRaw = currentArchive?.accessRole else {
            return [.read]
        }
        
        return permissions(forAccessRole: accessRaw)
    }
    
    func numberOfItemsForRole(_ role: AccessRole) -> Int {
        return memberSections[role]?.count ?? 0
    }
    
    func itemAtRow(_ row: Int, withRole role: AccessRole) -> Account? {
        return memberSections[role]?[row]
    }
    
    func getMembers(then handler: @escaping ServerResponse) {
        guard let currentArchive: ArchiveVOData = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive),
            let archiveNbr: String = currentArchive.archiveNbr else {
            return
        }
        
        let operation = APIOperation(MembersEndpoint.members(archiveNbr: archiveNbr))
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<AccountVO>.decoder
                    ), model.isSuccessful else {
                    return handler(.error(message: .errorMessage))
                }
            
                self.onGetMembersSucess(model.results.first?.data ?? [])
        
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func modifyMember(_ operation: MemberOperation, params: AddMemberParams, then handler: @escaping ServerResponse) {
        guard let currentArchive: ArchiveVOData = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive),
            let archiveNbr: String = currentArchive.archiveNbr else {
            return
        }
        
        let apiOperation = APIOperation(MembersEndpoint.modifyMember(operation: operation, archiveNbr: archiveNbr, params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<AccountVO>.decoder
                    ) else {
                    return handler(.error(message: .errorMessage))
                }
                guard model.isSuccessful  else {
                    let message = model.results.first?.message.first
                    let memberOperationFailedMessage = MembersOperationsError(rawValue: message ?? .errorUnknown)
                    handler(.error(message: memberOperationFailedMessage?.description))
                    return
                }
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    fileprivate func onGetMembersSucess(_ accounts: [AccountVO]) {
        self.members = accounts.map { AccountVM(accountVO: $0) }.sorted(by: { $0.status.value < $1.status.value })
        self.memberSections = Dictionary(grouping: self.members, by: { $0.accessRole })
    }
    
    func permissions(forAccessRole accessRoleRaw: String) -> [Permission] {
        let accessRole = AccessRole.roleForValue(accessRoleRaw)
        
        switch accessRole {
        case .owner:
            return [.read, .create, .upload, .edit, .delete, .move, .publish, .share, .archiveShare, .ownership]
            
        case .manager:
            return [.read, .create, .upload, .edit, .delete, .move, .publish, .share, .archiveShare]
            
        case .curator:
            return [.read, .create, .upload, .edit, .delete, .move, .publish, .share]
            
        case .editor:
            return [.read, .create, .upload, .edit]
            
        case .contributor:
            return [.read, .create, .upload]
            
        case .viewer:
            return [.read]
        }
    }
    
    func changeArchive(withArchiveId toArchiveId: Int, archiveNbr: String, completion: @escaping ((Bool) -> Void)) {
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: toArchiveId, archiveNbr: archiveNbr))
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder),
                    model.isSuccessful
                else {
                    completion(false)
                    return
                }
                
                let archive = model.results[0].data?[0].archiveVO
                try? PreferencesManager.shared.setCodableObject(archive, forKey: Constants.Keys.StorageKeys.archive)
                
                completion(true)
                return
                
            case .error:
                completion(false)
                return
                
            default:
                completion(false)
                return
            }
        }
    }
    
    func transferOwnership(email: String, then handler: @escaping ServerResponse) {
        guard let currentArchive: ArchiveVOData = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive),
            let archiveNbr: String = currentArchive.archiveNbr else {
            return
        }
        
        let apiOperation = APIOperation(ArchivesEndpoint.transferOwnership(archiveNbr: archiveNbr, primaryEmail: email))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<AccountVO>.decoder
                    ) else { return handler(.error(message: .errorMessage)) }
                
                guard
                    model.isSuccessful
                else {
                    let message = model.results.first?.message.first
                    let memberOperationFailedMessage = MembersOperationsError(rawValue: message ?? .errorUnknown)
                    handler(.error(message: memberOperationFailedMessage?.description))
                    return
                }
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
}
