//
//  OnboardingContainerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2024.

import Foundation

class OnboardingContainerViewModel: ObservableObject {
    @Published var contentType: OnboardingContentType = .none
    @Published var firstViewContentType: OnboardingContentType = .none
    @Published var bottomButtonsPadding: CGFloat =  40
    @Published var isBack = false
    @Published var isLoading: Bool = false
    @Published var initIsLoading: Bool = false
    @Published var showAlert: Bool = false
    
    @Published var archiveType: ArchiveType = .person
    @Published var archiveName: String = ""
    @Published var selectedPath: [OnboardingPath] = []
    @Published var selectedWhatsImportant: [OnboardingWhatsImportant] = []

    @Published var isArchiveAccepted: Bool = false
    var account: AccountVOData?
    
    @Published var allArchives: [OnboardingArchive] = []
    @Published var allArchivesVO: [ArchiveVO] = []
    @Published var fullName: String = ""
    var username: String = ""
    var password: String = ""
    var creatingNewArchive: Bool = false
    
    init(username: String?, password: String?) {
        isLoading = true
        initIsLoading = true
        self.username = username ?? ""
        self.password = password ?? ""
        self.fullName = AuthenticationManager.shared.session?.account.fullName ?? ""
        
        self.getAccountArchives { error in
            self.isLoading = false
            self.initIsLoading = false
            if error != nil {
                self.showAlert = true
            }
        }
    }
    
    func getAccountArchives(_ completionBlock: @escaping ((Error?) -> Void)) {
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            completionBlock(APIError.unknown)
            return
        }

        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: accountId))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .json(let response, _):
                guard let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                        model.isSuccessful else {
                    completionBlock(APIError.invalidResponse)
                    return
                }
                
                if let archives = model.results.first?.data {
                    allArchives = []
                    allArchivesVO = archives
                    for archive in archives {
                        if let fullName = archive.archiveVO?.fullName,
                           let status = archive.archiveVO?.status,
                           let archiveID = archive.archiveVO?.archiveID,
                            status == ArchiveVOData.Status.pending || status == ArchiveVOData.Status.ok {
                            allArchives.append(OnboardingArchive(fullname: fullName, accessType: AccessRole.roleForValue(archive.archiveVO?.accessRole).groupName, status: status, archiveID: archiveID, thumbnailURL: archive.archiveVO?.thumbURL200 ?? "", isThumbnailGenerated: archive.archiveVO?.thumbStatus != .genAvatar ? true : false))
                        }
                    }
                } else {
                    allArchives = []
                    allArchivesVO = []
                }
                
                completionBlock(nil)
                
            default:
                completionBlock(APIError.invalidResponse)
            }
        }
    }
    
    func trackEvents(action: AccountEventAction) {
        if(action == .skipGoals && !selectedPath.isEmpty) { return }
        if(action == .skipWhyPermanent && !selectedWhatsImportant.isEmpty) { return }
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: action,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}

