//
//  LegacyPlanningStatusViewModel.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 19.05.2023.

import Foundation

class LegacyPlanningStatusViewModel: ObservableObject, ViewModelInterface {
    
    var didLoad: (() -> Void)?
    
    private var archivesRepository: ArchivesRepository
    private var legacyRepository: LegacyPlanningRepository
    
    private var session: PermSession? {
        return PermSession.currentSession
    }
    
    var legacyData: [(archive: ArchiveVOData, steward: ArchiveSteward?)] = [] {
        didSet {
            didLoad?()
        }
    }
    
    init(archivesRepository: ArchivesRepository = ArchivesRepository(),
         legacyRepository: LegacyPlanningRepository = LegacyPlanningRepository()) {
        self.archivesRepository = archivesRepository
        self.legacyRepository = legacyRepository
        fetchArchives()
    }
    
    func fetchArchives() {
        guard let accountID = session?.account.accountID else {
            return
        }
        
        archivesRepository.getAccountArchives(accountId: accountID) {[weak self] result in
            switch result {
            case .failure(let error):
                break
            case .success(let archivesVO):
                let archives = archivesVO.compactMap { $0.archiveVO }
                self?.getStewards(archives: archives)
            }
        }
    }
    
    func getStewards(archives: [ArchiveVOData]) {
        Task {[weak self] in
            guard let strongSelf = self else { return }
            let stewards = try await archives.asyncMap(strongSelf.fetchSteward)
            await MainActor.run {
                strongSelf.legacyData = stewards
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
                    continuation.resume(throwing: error)
                case .success(let steward):
                    continuation.resume(returning: (archive, steward?.first))
                }
            }
        }
    }
}
