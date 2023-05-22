//
//  LegacyPlanningStatusViewModel.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 19.05.2023.

import Foundation
import Combine

struct Directive {
    var directiveId: Int
    var archiveId: Int
    var stewardName: String?
    var stewardEmail: String?
    var note: String
}

class LegacyPlanningStatusViewModel: ObservableObject, ViewModelInterface {
    
    private var archivesRepository = ArchivesRepository()
    
    private var session: PermSession? {
        didSet {
            PermSession.currentSession = session
        }
    }
    
    @Published var archives: [Directive] = []
    
    init(archivesRepository: ArchivesRepository = ArchivesRepository()) {
        self.archivesRepository = archivesRepository
        createMock()
    }
    
    func createMock() {
        var archives: [Directive] = []
        for i in 1...6 {
            archives.append(Directive(directiveId: i, archiveId: i, stewardName: i % 2 == 0 ? nil : "Name\(i)", stewardEmail: "email\(i)@email.com", note: "Note\(i)"))
        }
        
        self.archives.append(contentsOf: archives)
    }
    
    func fetchArchives() {
        guard let accountID = session?.account.accountID else {
            return
        }
        
        archivesRepository.getAccountArchives(accountId: accountID) { result in
            switch result {
            case .failure(let error):
                break
            case .success(let archives):
                break
            }
        }
    }
}
