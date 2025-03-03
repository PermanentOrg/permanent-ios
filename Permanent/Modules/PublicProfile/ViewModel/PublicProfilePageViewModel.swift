//
//  ProfilePageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class PublicProfilePageViewModel: ViewModelInterface {
    static let profileItemsUpdatedNotificationName = Notification.Name("PublicProfilePageViewModel.profileItemsUpdatedNotificationName")
    
    var archiveData: ArchiveVOData!
    var archiveType: ArchiveType!
    var newLocnId: Int?
    
    var isPubliclyVisible = false
    
    var profileItems = [ProfileItemModel]()
    
    var blurbProfileItem: BlurbProfileItem? {
        return profileItems.first(where: {$0 is BlurbProfileItem}) as? BlurbProfileItem
    }
    var descriptionProfileItem: DescriptionProfileItem? {
        return profileItems.first(where: {$0 is DescriptionProfileItem}) as? DescriptionProfileItem
    }
    var basicProfileItem: BasicProfileItem? {
        return profileItems.first(where: {$0 is BasicProfileItem}) as? BasicProfileItem
    }
    var profileGenderProfileItem: GenderProfileItem? {
        return profileItems.first(where: {$0 is GenderProfileItem}) as? GenderProfileItem
    }
    var birthInfoProfileItem: BirthInfoProfileItem? {
        return profileItems.first(where: {$0 is BirthInfoProfileItem}) as? BirthInfoProfileItem
    }
    var emailProfileItems: [EmailProfileItem] {
        return profileItems.filter({ $0 is EmailProfileItem }) as! [EmailProfileItem]
    }
    var socialMediaProfileItems: [SocialMediaProfileItem] {
        return profileItems.filter({ $0 is SocialMediaProfileItem }) as! [SocialMediaProfileItem]
    }
    var establishedInfoProfileItem: EstablishedInfoProfileItem? {
        return profileItems.first(where: {$0 is EstablishedInfoProfileItem}) as? EstablishedInfoProfileItem
    }
    var milestonesProfileItems: [MilestoneProfileItem] {
        return (profileItems.filter({ $0 is MilestoneProfileItem }) as! [MilestoneProfileItem]).sorted { lhs, rhs in
            guard let lhsStartDate = lhs.startDate else {
                return true
            }
            guard let rhsStartDate = rhs.startDate else {
                return false
            }
            
            return lhsStartDate > rhsStartDate
        }
    }
    var isEditDataEnabled: Bool {
        archiveData.permissions().contains(.archiveShare)
    }
    
    init(_ archiveData: ArchiveVOData) {
        self.archiveData = archiveData
        guard let archiveType = archiveData.type else { return }
        self.archiveType = ArchiveType.byRawValue(archiveType)
    }
    
    func getProfileViewData() -> [ProfileSection: [ProfileCellType]] {
        var profileViewData: [ProfileSection: [ProfileCellType]] = [:]
        profileViewData = [
            ProfileSection.about: [
            ],
            ProfileSection.information: [
            ],
            ProfileSection.onlinePresenceEmail: [
            ],
            ProfileSection.milestones: [
            ]
        ]
        
        if isEditDataEnabled {
            profileViewData[ProfileSection.profileVisibility] = [ ProfileCellType.profileVisibility ]
        }
        
        var aboutCells = [ProfileCellType]()
        if blurbProfileItem?.shortDescription?.isNotEmpty ?? false {
            aboutCells.append(.blurb)
        }
        if descriptionProfileItem?.longDescription?.isNotEmpty ?? false {
            aboutCells.append(.longDescription)
        }
        profileViewData[.about] = isEditDataEnabled ? [ProfileCellType.blurb, ProfileCellType.longDescription] : aboutCells
        
        var informationCells = [ProfileCellType]()
        if basicProfileItem?.fullName?.isNotEmpty ?? false {
            informationCells.append(.fullName)
        }
        if basicProfileItem?.nickname?.isNotEmpty ?? false {
            informationCells.append(.nickName)
        }
        guard let archiveType = archiveType else { return [:] }
        switch archiveType {
        case .person, .individual, .other, .unsure:
            if profileGenderProfileItem?.personGender?.isNotEmpty ?? false {
                informationCells.append(.gender)
            }
            if birthInfoProfileItem?.birthDate?.isNotEmpty ?? false {
                informationCells.append(.birthDate)
            }
            if birthInfoProfileItem?.birthLocationFormated?.isNotEmpty ?? false {
                informationCells.append(.birthLocation)
            }
            profileViewData[.information] = isEditDataEnabled ? [ProfileCellType.fullName, ProfileCellType.nickName, ProfileCellType.gender, ProfileCellType.birthDate, ProfileCellType.birthLocation] : informationCells
            
        case .family, .organization, .nonProfit, .community, .familyHistory:
            if establishedInfoProfileItem?.establishedDate?.isNotEmpty ?? false {
                informationCells.append(.establishedDate)
            }
            if establishedInfoProfileItem?.establishedLocationFormated?.isNotEmpty ?? false {
                informationCells.append(.establishedLocation)
            }
            
            profileViewData[.information] = isEditDataEnabled ? [ProfileCellType.fullName, ProfileCellType.nickName, ProfileCellType.establishedDate, ProfileCellType.establishedLocation] : informationCells
        }
        
        profileViewData[.onlinePresenceEmail] = emailProfileItems.map({ _ in .onlinePresenceEmail })
        profileViewData[.onlinePresenceLink] = socialMediaProfileItems.map({ _ in .onlinePresenceLink })
        
        profileViewData[.milestones] = milestonesProfileItems.map({ _ in .milestone })
        
        return profileViewData
    }
    
    func getAllByArchiveNbr(_ archive: ArchiveVOData, _ completionBlock: @escaping ((Error?) -> Void)) {
        guard let archiveId = archive.archiveID, let archiveNbr = archive.archiveNbr else {
            completionBlock(APIError.unknown)
            return
        }
        
        let getAllByArchiveNbr = APIOperation(PublicProfileEndpoint.getAllByArchiveNbr(archiveId: archiveId, archiveNbr: archiveNbr))
        getAllByArchiveNbr.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<ProfileItemVO>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(APIError.invalidResponse)
                    return
                }
                
                self.profileItems = model.results.first?.data?.compactMap({ $0.profileItemVO }) ?? []
                self.isPubliclyVisible = self.profileItems.allSatisfy({ $0.publicDT != nil })
                
                completionBlock(nil)
                return
                
            case .error:
                completionBlock(APIError.invalidResponse)
                return
                
            default:
                completionBlock(APIError.invalidResponse)
                return
            }
        }
    }
    
    func updateProfileVisibility(isVisible: Bool, completion: @escaping ServerResponse) {
        let itemsToUpdate = profileItems.filter { item in
            item.fieldNameUI != "profile.basic" && item.fieldNameUI != "profile.timezone" && item.fieldNameUI != "profile.description"
        }
        
        let apiOperation: APIOperation
        apiOperation = APIOperation(PublicProfileEndpoint.updateProfileVisibility(profileItemVOData: itemsToUpdate, isVisible: isVisible))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completion(.error(message: .errorMessage))
                    return
                }
                
                completion(.success)
                NotificationCenter.default.post(name: Self.profileItemsUpdatedNotificationName, object: nil)
                
            case .error:
                completion(.error(message: .errorMessage))
                return
                
            default:
                completion(.error(message: .errorMessage))
                return
            }
        }
    }
    
    func modifyPublicProfileItem(_ profileItemModel: ProfileItemModel, _ operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let apiOperation: APIOperation
        
        switch operationType {
        case .update, .create:
            if profileItemModel.publicDT == nil && isPubliclyVisible {
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                
                profileItemModel.publicDT = dateFormatter.string(from: Date())
            }
            
            apiOperation = APIOperation(PublicProfileEndpoint.safeAddUpdate(profileItemVOData: profileItemModel))
            
        case .delete:
            apiOperation = APIOperation(PublicProfileEndpoint.deleteProfileItem(profileItemVOData: profileItemModel))
        }
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<ProfileItemVO>.decoder),
                    model.isSuccessful,
                    let profileItemVO = model.results.first
                else {
                    completionBlock(false, APIError.invalidResponse, nil)
                    return
                }
                
                if operationType == .delete {
                    self.profileItems.removeAll(where: { $0.profileItemId == profileItemModel.profileItemId })
                    
                    completionBlock(true, nil, nil)
                } else if let newProfileItem = profileItemVO.data?.first?.profileItemVO {
                    if let idx = self.profileItems.firstIndex(where: { $0.profileItemId == profileItemModel.profileItemId }) {
                        self.profileItems.remove(at: idx)
                        self.profileItems.insert(newProfileItem, at: idx)
                    } else {
                        self.profileItems.append(newProfileItem)
                    }
                    
                    completionBlock(true, nil, newProfileItem.profileItemId)
                }
                
                
                self.trackEditProfileEvent(profileItemId: String(profileItemModel.profileItemId ?? 0))
        
                NotificationCenter.default.post(name: Self.profileItemsUpdatedNotificationName, object: nil)
                
            case .error:
                completionBlock(false, APIError.invalidResponse, nil)
                return
                
            default:
                completionBlock(false, APIError.invalidResponse, nil)
                return
            }
        }
    }
    
    func modifyBlurbProfileItem(profileItemId: Int? = nil, newValue: String, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newBlurbItem = BlurbProfileItem()
        newBlurbItem.shortDescription = newValue
        newBlurbItem.archiveId = archiveData.archiveID
        newBlurbItem.profileItemId = profileItemId
        
        modifyPublicProfileItem(newBlurbItem, operationType, completionBlock)
    }
    
    func modifyDescriptionProfileItem(profileItemId: Int? = nil, newValue: String, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = DescriptionProfileItem()
        newProfileItem.longDescription = newValue
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        
        // Description is always public
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        newProfileItem.publicDT = dateFormatter.string(from: Date())
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func modifyBasicProfileItem(profileItemId: Int? = nil, newValueFullname: String? = nil, newValueNickName: String? = nil, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = BasicProfileItem()
        newProfileItem.fullName = newValueFullname
        newProfileItem.nickname = newValueNickName
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        
        // Basic item is always public
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        newProfileItem.publicDT = dateFormatter.string(from: Date())
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func modifyGenderProfileItem(profileItemId: Int? = nil, newValueGender: String? = nil, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = GenderProfileItem()
        newProfileItem.personGender = newValueGender
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func modifyBirthInfoProfileItem(profileItemId: Int? = nil, newValueBirthDate: String? = nil, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = BirthInfoProfileItem()
        if let valueBirthDate = newValueBirthDate,
           valueBirthDate.isEmpty {
            newProfileItem.birthDate = nil
        } else {
            newProfileItem.birthDate = newValueBirthDate
        }
        newProfileItem.birthLocation = birthInfoProfileItem?.birthLocation
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        if let newLocnId = newLocnId {
            newProfileItem.locnId1 = newLocnId
        } else {
            newProfileItem.locnId1 = birthInfoProfileItem?.locationID
        }
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func modifyEmailProfileItem(profileItemId: Int? = nil, newValue: String? = nil, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = EmailProfileItem()
        newProfileItem.email = newValue
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func modifySocialMediaProfileItem(profileItemId: Int? = nil, newValue: String? = nil, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = SocialMediaProfileItem()
        newProfileItem.link = newValue
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func createNewBirthProfileItem(newLocation: LocnVO?) {
        let newProfileItem = BirthInfoProfileItem()
        newProfileItem.birthLocation = newLocation
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.locnId1 = newLocation?.locnID
        
        profileItems.append(newProfileItem)
    }
    
    func modifyEstablishedInfoProfileItem(profileItemId: Int? = nil, newValue: String? = nil, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newProfileItem = EstablishedInfoProfileItem()
        if let valueEstablishedDate = newValue,
           valueEstablishedDate.isEmpty {
            newProfileItem.establishedDate = nil
        } else {
            newProfileItem.establishedDate = newValue
        }
        newProfileItem.establishedLocation = establishedInfoProfileItem?.establishedLocation
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.profileItemId = profileItemId
        if let newLocnId = newLocnId {
            newProfileItem.locnId1 = newLocnId
        } else {
            newProfileItem.locnId1 = establishedInfoProfileItem?.locationID
        }
        
        modifyPublicProfileItem(newProfileItem, operationType, completionBlock)
    }
    
    func createNewEstablishedInfoProfileItem(newLocation: LocnVO?) {
        let newProfileItem = EstablishedInfoProfileItem()
        newProfileItem.establishedLocation = newLocation
        newProfileItem.archiveId = archiveData.archiveID
        newProfileItem.locnId1 = newLocation?.locnID
        
        profileItems.append(newProfileItem)
    }
    
    func updateBasicProfileItem(fullNameNewValue: String?, nicknameNewValue: String?, _ completion: @escaping (Bool) -> Void ) {
        var textFieldIsEmpty = (false, false)
        var textFieldHaveNewValue = (false, false)
        
        if let savedFullName = basicProfileItem?.fullName,
           savedFullName != fullNameNewValue {
            textFieldHaveNewValue.0 = true
        } else if (fullNameNewValue ?? "").isNotEmpty {
            textFieldHaveNewValue.0 = true
        }
        
        if let savedNickname = basicProfileItem?.nickname,
           savedNickname != nicknameNewValue {
            textFieldHaveNewValue.1 = true
        } else if (nicknameNewValue ?? "").isNotEmpty {
            textFieldHaveNewValue.1 = true
        }
        
        if let fullName = fullNameNewValue,
           fullName.isEmpty {
            textFieldIsEmpty.0 = true
        }
        
        if let nickname = nicknameNewValue,
           nickname.isEmpty {
            textFieldIsEmpty.1 = true
        }
        
        if textFieldHaveNewValue == (false, false) {
            completion(true)
            return
        }
        
        if textFieldHaveNewValue.0 || textFieldHaveNewValue.1,
           textFieldIsEmpty == (true, true) {
            modifyBasicProfileItem(profileItemId: basicProfileItem?.profileItemId, operationType: .delete, { result, error, itemId in
                if result {
                    self.basicProfileItem?.profileItemId = nil
                    completion(true)
                    return
                } else {
                    completion(false)
                    return
                }
            })
        } else {
            modifyBasicProfileItem(profileItemId: basicProfileItem?.profileItemId, newValueFullname: fullNameNewValue, newValueNickName: nicknameNewValue, operationType: .update, { result, error, itemId in
                if result {
                    if self.basicProfileItem?.profileItemId == nil {
                        self.basicProfileItem?.profileItemId = itemId
                    }
                    completion(true)
                    return
                } else {
                    completion(false)
                    return
                }
            })
        }
    }
    
    func updateGenderProfileItem(genderNewValue: String?, _ completion: @escaping (Bool) -> Void ) {
        var textFieldIsEmpty = false
        var textFieldHaveNewValue = false
        
        if let savedProfileGender = profileGenderProfileItem?.personGender,
           savedProfileGender != genderNewValue {
            textFieldHaveNewValue = true
        } else if (genderNewValue ?? "").isNotEmpty {
            textFieldHaveNewValue = true
        }
        
        if let value = genderNewValue,
           value.isEmpty {
            textFieldIsEmpty = true
        }
        
        if textFieldHaveNewValue == false {
            completion(true)
            return
        }
        
        if textFieldHaveNewValue,
           textFieldIsEmpty {
            modifyGenderProfileItem(profileItemId: profileGenderProfileItem?.profileItemId, operationType: .delete, { result, error, itemId in
                if result {
                    self.profileGenderProfileItem?.profileItemId = nil
                    completion(true)
                    return
                } else {
                    completion(false)
                    return
                }
            })
        } else {
            modifyGenderProfileItem(profileItemId: profileGenderProfileItem?.profileItemId, newValueGender: genderNewValue, operationType: .update, { result, error, itemId in
                if result {
                    if self.profileGenderProfileItem?.profileItemId == nil {
                        self.profileGenderProfileItem?.profileItemId = itemId
                    }
                    completion(true)
                    return
                } else {
                    completion(false)
                    return
                }
            })
        }
    }
    
    func updateBirthInfoProfileItem(birthDateNewValue: String?, _ completion: @escaping (Bool) -> Void ) {
        var textFieldHaveNewValue = false
        
        if let savedBirthDate = birthInfoProfileItem?.birthDate,
           savedBirthDate != birthDateNewValue {
            textFieldHaveNewValue = true
        } else if (birthDateNewValue ?? "").isNotEmpty {
            textFieldHaveNewValue = true
        }
        
        if textFieldHaveNewValue == false && newLocnId == nil {
            completion(true)
            return
        }
        
        if textFieldHaveNewValue || (newLocnId != nil) {
            modifyBirthInfoProfileItem(profileItemId: birthInfoProfileItem?.profileItemId, newValueBirthDate: birthDateNewValue, operationType: .update, { result, error, itemId in
                if result {
                    if self.birthInfoProfileItem?.profileItemId == nil {
                        self.birthInfoProfileItem?.profileItemId = itemId
                    }
                    
                    if self.newLocnId != nil {
                        self.newLocnId = nil
                    }
                    
                    completion(true)
                    return
                } else {
                    completion(false)
                    return
                }
            })
        } else {
            completion(true)
            return
        }
    }
    
    func updateEstablishedInfoProfileItem(newValue: String?, _ completion: @escaping (Bool) -> Void ) {
        var textFieldHaveNewValue = false
        
        if let savedDate = establishedInfoProfileItem?.establishedDate,
           savedDate != newValue {
            textFieldHaveNewValue = true
        } else if (newValue ?? "").isNotEmpty {
            textFieldHaveNewValue = true
        }
        
        if textFieldHaveNewValue == false && newLocnId == nil {
            completion(true)
            return
        }
        
        if textFieldHaveNewValue || (newLocnId != nil) {
            modifyEstablishedInfoProfileItem(profileItemId: establishedInfoProfileItem?.profileItemId, newValue: newValue, operationType: .update, { result, error, itemId in
                if result {
                    if self.establishedInfoProfileItem?.profileItemId == nil {
                        self.establishedInfoProfileItem?.profileItemId = itemId
                    }
                    
                    if self.newLocnId != nil {
                        self.newLocnId = nil
                    }
                    
                    completion(true)
                    return
                } else {
                    completion(false)
                    return
                }
            })
        } else {
            completion(true)
            return
        }
    }
    
    func updateMilestoneProfileItem(newValue: MilestoneProfileItem, _ completion: @escaping (Bool) -> Void ) {
        modifyPublicProfileItem(newValue, .update, { result, error, itemId in
            if result {
                completion(true)
                return
            } else {
                completion(false)
                return
            }
        })
    }
    
    func deleteMilestoneProfileItem(milestone: MilestoneProfileItem?, _ completion: @escaping (Bool) -> Void ) {
        guard let milestone = milestone else {
            completion(false)
            return
        }
        
        modifyPublicProfileItem(milestone, .delete, { result, error, itemId in
            if result {
                completion(true)
                return
            } else {
                completion(false)
                return
            }
        })
    }
    
    func validateLocation(lat: Double, long: Double, completion: @escaping ((LocnVO?) -> Void)) {
        let params: GeomapLatLongParams = (lat, long)
        let apiOperation = APIOperation(LocationEndpoint.geomapLatLong(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<LocnVOData> = JSONHelper.decoding(from: json, with: APIResults<LocnVOData>.decoder), model.isSuccessful else {
                    completion(nil)
                    return
                }
                guard let locnVO = model.results.first?.data?.first?.locnVO else {
                    completion(nil)
                    return
                }
                self.postLocation(location: locnVO) { result in
                    if let postLocnVO = result {
                        completion(postLocnVO)
                    } else {
                        completion(nil)
                    }
                }
                
            case .error(_, _):
                completion(nil)
                
            default:
                completion(nil)
            }
        }
    }
    
    func postLocation(location: LocnVO, completion: @escaping ((LocnVO?) -> Void)) {
        let apiOperation = APIOperation(LocationEndpoint.locnPost(location: location))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<LocnVOData> = JSONHelper.decoding(from: json, with: APIResults<LocnVOData>.decoder), model.isSuccessful else {
                    completion(nil)
                    return
                }
                let locnVO: LocnVO? = model.results.first?.data?.first?.locnVO
                completion(locnVO)
                
            case .error(_, _):
                completion(nil)
                
            default:
                completion(nil)
            }
        }
    }
    
    func trackEditProfileEvent(profileItemId: String) {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: ProfileItemEventAction.update,
                                                       entityId: profileItemId) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
    
    func trackPageViewEvent() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.openArchiveProfile,
                                                       entityId: String(accountId),
                                                       data: ["page":"Archive Profile"]) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
