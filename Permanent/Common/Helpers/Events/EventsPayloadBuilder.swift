//
//  EventsPayloadBuilder.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 05.11.2024.

import Foundation

// MARK: - Action Enums

protocol EventAction: RawRepresentable<String> {
    var entity: String { get }
    var event: String { get }
    var action: String { get }
}

extension EventAction {
    
    var action: String {
        return self.rawValue
    }
}

enum AccountEventAction: String, EventAction {
    case create
    case login
    case startOnboarding = "start_onboarding"
    case submitGoals = "submit_goals"
    case submitReasons = "submit_reasons"
    case openAccountMenu = "open_account_menu"
    case openArchiveMenu = "open_archive_menu"
    case openStorageModal = "open_storage_modal"
    case purchaseStorage = "purchase_storage"
    case openPromoEntry = "open_promo_entry"
    case submitPromo = "submit_promo"
    case skipCreateArchive = "skip_create_archive"
    case skipGoals = "skip_goals"
    case skipWhyPermanent = "skip_why_permanent"
    case openLoginInfo = "open_login_info"
    case openVerifyEmail = "open_verify_email"
    case openBillingInfo = "open_billing_info"
    case update = "update"
    case openLegacyContact = "open_legacy_contact"
    case openArchiveSteward = "open_archive_steward"
    case openPrivateWorkspace = "open_private_workspace"
    case openPublicWorkspace = "open_public_workspace"
    case openSharedWorkspace = "open_shared_workspace"
    case openPublicGallery = "open_public_gallery"
    case openRedeemGift = "open_redeem_gift"
    case openShareModal = "open_share_modal"
    case copyShareLink = "copy_share_link"
    
    var entity: String {
        return "account"
    }

    var event: String {
        switch self {
        case .create:
            return "Sign up"
        case .login:
            return "Sign in"
        case .startOnboarding:
            return "Onboarding: start"
        case .submitGoals:
            return "Onboarding: goals"
        case .submitReasons:
            return "Onboarding: reason"
        case .openAccountMenu:
            return "Screen View"
        case .openArchiveMenu:
            return "Screen View"
        case .openStorageModal:
            return "Screen View"
        case .purchaseStorage:
            return "Purchase Storage"
        case .openPromoEntry:
            return "Screen View"
        case .submitPromo:
            return "Redeem Gift"
        case .skipCreateArchive:
            return "Skip create archive"
        case .skipGoals:
            return "Skip goals"
        case .skipWhyPermanent:
            return "Skip why permanent"
        case .openLoginInfo:
            return "View Login Info"
        case .openVerifyEmail:
            return "Verify Email"
        case .openBillingInfo:
            return "View Billing Info"
        case .update:
            return "Edit Address"
        case .openLegacyContact:
            return "View Legacy Contact"
        case .openArchiveSteward:
            return "View Archive Steward"
        case .openPrivateWorkspace:
            return "View Private Workspace"
        case .openPublicWorkspace:
            return "View Public Workspace"
        case .openSharedWorkspace:
            return "View Shared Workspace"
        case .openPublicGallery:
            return "View Public Gallery"
        case .openRedeemGift:
            return "View Redeem Gift"
        case .openShareModal:
            return "Share"
        case .copyShareLink:
            return "Copy Share Link"
        }
    }
}

enum RecordEventAction: String, EventAction {
    
    case initiateUpload = "initiate_upload"
    case submit = "submit"
    case move = "move"
    case copy = "copy"
    
    var entity: String {
        return "record"
    }


    var event: String {
        switch self {
        case .initiateUpload:
            return "Initiate Upload"
        case .submit:
            return "Finalize Upload"
        case .move:
            return "Move Record"
        case .copy:
            return "Copy Record"
        }
    }
}

enum ProfileItemEventAction: String, EventAction {
    case update = "update"
    
    var entity: String {
        return "profile_item"
    }

    var event: String {
        switch self {
        case .update:
            return "Edit Archive Profile"
        }
    }
}

enum LegacyContactEventAction: String, EventAction {
    case create = "create"
    case update = "update"
    
    var entity: String {
        return "legacy_contact"
    }

    var event: String {
        switch self {
        case .create, .update:
            return "Edit Legacy Contact"
        }
    }
}

enum DirectiveEventAction: String, EventAction {
    case create = "create"
    case update = "update"
    
    var entity: String {
        return "directive"
    }


    var event: String {
        switch self {
        case .create, .update:
            return "Edit Archive Steward"
        }
    }
}

enum ArchiveEventAction: String, EventAction {
    case create = "create"
    
    var entity: String {
        return "archive"
    }

    var event: String {
        switch self {
        case .create:
            return "Create Archive"
        }
    }
}

enum FolderEventAction: String, EventAction {
    case move = "move"
    case copy = "copy"
    
    var entity: String {
        return "folder"
    }

    var event: String {
        switch self {
        case .move:
            return "Move Folder"
        case .copy:
            return "Copy Folder"
        }
    }
}

struct EventsPayloadBuilder {
    
    static func build(eventAction: any EventAction,
               version: Int = 1,
               entityId: String? = nil,
               data: [String: String] = [String:String]()) -> EventsPayload? {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID else {
            return nil
        }
        let defaultEnv = APIEnvironment.defaultEnv
        let distinctId = defaultEnv == .production ? String(accountId) : "\(defaultEnv):\(String(accountId))"
        let payload = EventsPayload(entity: eventAction.entity,
                                    action: eventAction.action,
                                    version: 1,
                                    entityId: entityId,
                                    body: EventsBodyPayload(event: eventAction.event,
                                                            distinctId: distinctId,
                                                            data: data))
        return payload
    }
    
}
