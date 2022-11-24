//
//  Constants.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit
import CoreLocation

typealias ButtonAction = () -> Void
typealias TooltipAction = (CGPoint, String) -> Void
typealias CellButtonTapAction = (UITableViewCell) -> Void

struct Font { }

struct Text {
    static let style = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20), lineHeight: CGFloat(27)), NSTextAlignment.center)
    static let style2 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.center)
    static let style3 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(24)), NSTextAlignment.natural)
    static let style4 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.natural)
    static let style5 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(20)), NSTextAlignment.natural)
    static let style6 = TextStyle(UIFont(name: "OpenSans-Italic", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.center)
    static let style7 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.natural)
    static let style8 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
    static let style9 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(24)), NSTextAlignment.natural)
    static let style10 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(45)), NSTextAlignment.natural)
    static let style11 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
    static let style12 = TextStyle(UIFont(name: "OpenSans-Regular", size: 12)!, TextStyle.calculateSpacing(fontSize: CGFloat(12), lineHeight: CGFloat(17)), NSTextAlignment.center)
    static let style13 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.center)
    static let style14 = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20), lineHeight: CGFloat(27)), NSTextAlignment.center)
    static let style15 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 13)!, TextStyle.calculateSpacing(fontSize: CGFloat(13), lineHeight: CGFloat(18)), NSTextAlignment.natural)
    static let style16 = TextStyle(UIFont(name: "OpenSans-Bold", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
    static let style17 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.natural)
    static let style18 = TextStyle(UIFont(name: "OpenSans-Bold", size: 12)!, TextStyle.calculateSpacing(fontSize: CGFloat(12), lineHeight: CGFloat(17)), NSTextAlignment.natural)
    static let style19 = TextStyle(UIFont(name: "OpenSans-Italic", size: 12)!, TextStyle.calculateSpacing(fontSize: CGFloat(12), lineHeight: CGFloat(17)), NSTextAlignment.natural)
    static let style20 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 12)!, TextStyle.calculateSpacing(fontSize: CGFloat(12), lineHeight: CGFloat(17)), NSTextAlignment.natural)
    static let style29 = TextStyle(UIFont(name: "OpenSans-Regular", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(45)), NSTextAlignment.center)
    static let style30 = TextStyle(UIFont(name: "OpenSans-Regular", size: 10)!, TextStyle.calculateSpacing(fontSize: CGFloat(10), lineHeight: CGFloat(12)), NSTextAlignment.center)
    static let style31 = TextStyle(UIFont(name: "OpenSans-Bold", size: 10)!, TextStyle.calculateSpacing(fontSize: CGFloat(10), lineHeight: CGFloat(12)), NSTextAlignment.center)
    static let style32 = TextStyle(UIFont(name: "OpenSans-Bold", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.natural)
    static let style33 = TextStyle(UIFont(name: "OpenSans-Bold", size: 24)!, TextStyle.calculateSpacing(fontSize: CGFloat(24), lineHeight: CGFloat(27)), NSTextAlignment.center)
    static let style34 = TextStyle(UIFont(name: "OpenSans-Regular", size: 15)!, TextStyle.calculateSpacing(fontSize: CGFloat(15), lineHeight: CGFloat(20)), NSTextAlignment.natural)
    static let style35 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 15)!, TextStyle.calculateSpacing(fontSize: CGFloat(15), lineHeight: CGFloat(20)), NSTextAlignment.natural)
    static let style36 = TextStyle(UIFont(name: "OpenSans-Regular", size: 8)!, TextStyle.calculateSpacing(fontSize: CGFloat(8), lineHeight: CGFloat(12)), NSTextAlignment.center)
    static let style37 = TextStyle(UIFont(name: "OpenSans-Regular", size: 10)!, TextStyle.calculateSpacing(fontSize: CGFloat(10), lineHeight: CGFloat(12)), NSTextAlignment.center)
    static let style38 = TextStyle(UIFont(name: "OpenSans-Italic", size: 10)!, TextStyle.calculateSpacing(fontSize: CGFloat(10), lineHeight: CGFloat(12)), NSTextAlignment.center)
    static let style39 = TextStyle(UIFont(name: "OpenSans-Regular", size: 13)!, TextStyle.calculateSpacing(fontSize: CGFloat(13), lineHeight: CGFloat(13)), NSTextAlignment.center)
    static let style40 = TextStyle(UIFont(name: "OpenSans-Bold", size: 8)!, TextStyle.calculateSpacing(fontSize: CGFloat(8), lineHeight: CGFloat(12)), NSTextAlignment.center)
}

struct Constants {
    struct API {
        struct FileType {}
        struct AccountStatus {}
        struct InviteStatus {}
        struct NotificationType {}
        struct Locations{}
    }

    struct Design {}
    struct URL {}
    struct Keys {
        struct StorageKeys {}
    }

    // TODO: Move these to String
    static let onboardingTextBold = [
        "Share your most cherished \nmemories with total control.",
        "Preserve your most important \ndocuments with peace of mind.",
        "We will never mine your data, \nclaim your copyright or invade \nyour privacy."
    ]
    static let onboardingTextNormal = [
        "Easily create links to privately shared \ncontent that limit how many people can \naccess the content or for how long.",
        "We are the most comprehensive consumer \ndigital preservation platform available today.",
        "We are backed by mission-driven \ncultural heritage nonprofit dedicated to \nthe public good."
    ]
    static let onboardingBottomButtonText = [
        "Next",
        "Next",
        "Get Started"
    ]
    static let onboardingPageImage = ["1", "2", "3"]
}

extension Constants.Design {
    static let customButtonHeight: CGFloat = 40
    static let customButtonCornerRadius: CGFloat = 20
    static let actionButtonRadius: CGFloat = 4
    static let sheetCornerRadius: CGFloat = 4
    static let bannerHeight: CGFloat = 45
    static let pickerHeight: CGFloat = 200
    static let numberOfGridItemsPerRow = 2
    static let avatarRadius: CGFloat = 17.0
    static let shortNotificationBarAnimationDuration: Double = 0.8
    static let longNotificationBarAnimationDuration: Double = 2.2
}

extension Constants.API {
    static let typeAuthCreatedAccountEmail = "type.auth.created_account_email"
    static let typeAuthCreatedAccountText = "type.auth.created_account_text"
    static let typeAuthEmail = "type.auth.email"
    static let typeAuthKeepLoggedIn = "type.auth.keep_logged_in"
    static let typeAuthPassword = "type.auth.password"
    static let typeAuthPermSession = "type.auth.perm_session"
    static let typeAuthPhone = "type.auth.phone"
    static let typeAuthRememberMe = "type.auth.remember_me"
    static let typeAuthSession = "type.auth.session"
    static let typeAuthSignup = "type.auth.signup"
    static let typeAuthVault = "type.auth.vault"
    static let typeAuthMFA = "type.auth.mfa"
    static let typeAuthMFAValidation = "type.auth.mfaValidation"
}

extension Constants.API.FileType {
    static let myFilesFolder = "My Files"

    static let typeFolderRootPrivate = "type.folder.root.private"
    static let typeFolderRootPublic = "type.folder.root.public"
    static let typeFolderPrivate = "type.folder.private"
    static let typeRecordImage = "type.record.image"
}

extension Constants.URL {
    static let termsConditionsURL = "https://www.permanent.org/terms/"
}

extension Constants.API.AccountStatus {
    static let pending = "status.generic.pending"
    static let ok = "status.generic.ok"
}

extension Constants.API.InviteStatus {
    static let accepted = "status.invite.accepted"
    static let revoked = "status.invite.revoked"
    static let pending = "status.invite.pending"
    static let rejected = "status.invite.rejected"
}

extension Constants.API.NotificationType {
    static let paShare = "type.notification.pa_share"
    static let relationship = "type.notification.relationship"
    static let account = "type.notification.cleanup_bad_upload"
}

extension Constants.Keys.StorageKeys {
    static let isNewUserStorageKey = "isNewUser"
    static let uploadFilesKey = "uploadFilesKey"
    static let shareURLToken = "shareURLTokenStorageKey"
    static let publicURLToken = "publicURLTokenKey"
    static let sharedFileKey = "sharedFileKey"
    static let sharedFolderKey = "sharedFolderKey"
    static let requestPAAccess = "requestPAAccess"
    static let requestLinkAccess = "requestLinkAccess"
    static let biometricsAuthEnabled = "biometricsAuthOffEnabledKey"
    static let fcmPushTokenKey = "fcmPushTokenKey"
    static let signUpInvitationsAccepted = "signUpInvitationsAccepted"
    static let modelVersion = "modelVersion"
    static let minAppVersion = "minAppVersion"
}

extension Constants.API.Locations {
    static let initialLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 30.286807215890345, longitude: -97.81482923937635)
}
