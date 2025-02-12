//
//  LegacyPlanningStatusViewModel.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 19.05.2023.

import Foundation

class LegacyPlanningStatusViewModel: ObservableObject, ViewModelInterface {
    
    var didLoad: (() -> Void)?
    var isLoading: ((Bool) -> Void)?
    var showError: ((APIError) -> Void)?
    
    private var archivesRepository: ArchivesRepository
    private var legacyRepository: LegacyPlanningRepository
    
    var session: PermSession? {
        return PermSession.currentSession
    }
    
    var legacyArchiveData: [(archive: ArchiveVOData, steward: ArchiveSteward?)] = []
    var legacyContact: AccountSteward?
    
    init(archivesRepository: ArchivesRepository = ArchivesRepository(),
         legacyRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.archivesRepository = archivesRepository
        self.legacyRepository = legacyRepository
    }
    
    // MARK: Steward
    
    func getStewards() {
        isLoading?(true)
        Task {[weak self] in
            guard let strongSelf = self else { return }
            
            do {
                let archives = try await strongSelf.fetchArchives().filter({ archive in
                    return archive.permissions().contains(.legacyPlanning)
                })
                strongSelf.legacyArchiveData = try await archives.asyncMap(strongSelf.fetchSteward)
                strongSelf.legacyContact = try await strongSelf.fetchAccount()
                
                await MainActor.run {
                    strongSelf.isLoading?(false)
                    strongSelf.didLoad?()
                }
            }
            catch {
                await MainActor.run {
                    strongSelf.isLoading?(false)
                    if let apiError = error as? APIError {
                        strongSelf.showError?(apiError)
                    }
                }
            }
        }
    }
    
    // MARK: Account
    
    func fetchAccount() async throws -> AccountSteward? {
        return try await withCheckedThrowingContinuation { continuation in
            legacyRepository.getLegacyContact { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let contact):
                    continuation.resume(returning: contact?.first)
                }
            }
        }
    }
    
    // MARK: Archives
    
    func fetchArchives() async throws -> [ArchiveVOData] {
        guard let accountID = session?.account.accountID else {
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            archivesRepository.getAccountArchives(accountId: accountID) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let archivesVO):
                    let archives = archivesVO.compactMap { $0.archiveVO }
                    continuation.resume(returning: archives)
                }
            }
        }
    }
    
    func fetchSteward(archive: ArchiveVOData) async throws -> (ArchiveVOData, ArchiveSteward?) {
        guard let archiveId = archive.archiveID else {
            return (archive, nil)
        }
        return try await withCheckedThrowingContinuation { continuation in
            legacyRepository.getArchiveSteward(archiveId: archiveId) { result in
                switch result {
                case .failure(let error):
                    if let error = error as? APIError, error == .noData {
                        continuation.resume(returning: (archive, nil))
                    } else {
                        continuation.resume(throwing: error)
                    }
                case .success(let steward):
                    continuation.resume(returning: (archive, steward?.first))
                }
            }
        }
    }
}
