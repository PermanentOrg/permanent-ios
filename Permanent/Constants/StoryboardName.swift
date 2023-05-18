//
//  StoryboardNames.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//

import Foundation

enum StoryboardName: String {
    case main
    case authentication
    case launch
    case onboarding
    case welcomePage
    case members
    case share
    case accountInfo
    case invitations
    case settings
    case archives
    case profile
    case donate
    case accountOnboarding
    case archiveSettings
    case legacyPlanning
    
    var name: String {
        switch self {
        case .accountOnboarding: return "AccountOnboarding"
        case .archiveSettings: return "ArchiveSettings"
        case .legacyPlanning: return "LegacyPlanning"
            
        default: return self.rawValue.capitalized
        }
    }
}

enum ViewControllerId: String {
    case main
    case signUp
    case onboarding
    case login
    case recoverPassword
    case welcomePage
    case verificationCode
    case termsConditions
    case twoStepVerification
    case biometrics
    case fabActionSheet
    case sideMenu
    case rightSideMenu
    case share
    case shares
    case members
    case manageLink
    case accountInfo
    case accountDelete
    case accountSettings
    case sharePreview
    case invitations
    case filePreview
    case fileDetailsOnTap
    case locationSetOnTap
    case tagDetails
    case archives
    case passwordUpdate
    case profilePage
    case profileAboutPage
    case profilePersonalInfoPage
    case search
    case publicArchive
    case publicArchiveFileBrowser
    case onlinePresence
    case addOnlinePresence
    case milestones
    case addMilestones
    case updateApp
    case loadingScreen
    case donate
    case accountOnboarding
    case accountOnboardingPg1
    case accountOnboardingPg2
    case accountOnboardingPg3
    case accountOnboardingPg1Pending
    case accountOnboardingPg2Pending
    case publicGallery
    case tagManagement
    case shareManagement
    case shareManagementAccessRoles
    case tagsOptions
    case legacyPlanningIntro
    case legacyPlanningLoading
    case legacyPlanningSteward
    case trustedSteward

    var value: String {
        switch self {
        case .signUp:
            return "SignUp"
            
        case .verificationCode:
            return "VerificationCode"
            
        case .termsConditions:
            return "TermsConditions"
            
        case .twoStepVerification:
            return "TwoStepVerification"
            
        case .fabActionSheet:
            return "FABActionSheet"
            
        case .sideMenu:
            return "SideMenu"
            
        case .rightSideMenu:
            return "RightSideMenu"
            
        case .manageLink:
            return "ManageLink"
            
        case .accountInfo:
            return "AccountInfo"
            
        case .accountDelete:
            return "AccountDelete"
            
        case .accountSettings:
            return "AccountSettings"
            
        case .sharePreview:
            return "SharePreview"
            
        case .filePreview:
            return "WebViewer"
            
        case .fileDetailsOnTap:
            return "FileDetailsOnTap"
            
        case .locationSetOnTap:
            return "LocationSetOnTap"
            
        case .tagDetails:
            return "TagDetails"
            
        case .welcomePage:
            return "WelcomePage"
            
        case .passwordUpdate:
            return "PasswordUpdate"
            
        case .profilePage:
            return "ProfilePage"
            
        case .profileAboutPage:
            return "AboutPage"
            
        case .profilePersonalInfoPage:
            return "PersonalInformationPage"
            
        case .search:
            return "Search"
            
        case .publicArchive:
            return "publicArchiveVC"
            
        case .publicArchiveFileBrowser:
            return "publicArchiveFileBrowserVC"
            
        case .onlinePresence:
            return "onlinePresenceVC"
            
        case .addOnlinePresence:
            return "addOnlinePresenceVC"
            
        case .milestones:
            return "milestonesVC"
            
        case .addMilestones:
            return "addMilestonesVC"
            
        case .updateApp:
            return "updateApplication"
            
        case .loadingScreen:
            return "loadingScreen"
            
        case .donate:
            return "donate"

        case .accountOnboarding:
            return "accountOnboarding"
            
        case .accountOnboardingPg1:
            return "accountOnboardingPg1"
            
        case .accountOnboardingPg2:
            return "accountOnboardingPg2"
            
        case .accountOnboardingPg3:
            return "accountOnboardingPg3"
            
        case .accountOnboardingPg1Pending:
            return "accountOnboardingPg1Pending"
            
        case .accountOnboardingPg2Pending:
            return "accountOnboardingPg2Pending"

        case .publicGallery:
            return "publicGallery"
            
        case .recoverPassword:
            return "RecoverPassword"

        case .tagManagement:
            return "TagManagement"
            
        case .shareManagement:
            return "ShareManagement"
            
        case .shareManagementAccessRoles:
            return "ShareManagementAccessRoles"
            
        case .tagsOptions:
            return "TagsOptions"
            
        case .legacyPlanningIntro:
            return "LegacyPlanningIntro"
            
        case .legacyPlanningLoading:
            return "LegacyPlanningLoading"
            
        case .legacyPlanningSteward:
            return "LegacyPlanningSteward"
            
        case .trustedSteward:
            return "TrustedSteward"
            
        default:
            return self.rawValue.capitalized
        }
    }
}
