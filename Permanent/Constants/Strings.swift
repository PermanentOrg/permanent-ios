//  
//  Strings.swift
//  Permanent
//
//  Created by Adrian Creteanu on 06/11/2020.
//

import Foundation

extension String {
    static var signup: String { return "Signup".localized() }
    static var login: String { return "Login".localized() }
    static var fullName: String { return "FullName".localized() }
    static var email: String { return "Email".localized() }
    static var password: String { return "Password".localized() }
    static var forgotPassword: String { return "ForgotPassword".localized() }
    static var copyrightText: String { return "CopyrightText".localized() }
    static var alreadyMember: String { return "AlreadyMember".localized() }
    static var next: String { return "Next".localized() }
    static var enterVerificationCode: String { return "EnterVerificationCode".localized() }
    static var enterCode: String { return "EnterCode".localized() }
    static var error: String { return "Error".localized() }
    static var errorMessage: String { return "ErrorMessage".localized() }
    static var ok: String { return "Ok".localized() }
    static var accept: String { return "Accept".localized() }
    static var decline: String { return "Decline".localized() }
    static var cancelAll: String { return "Cancel all"}
    static var termsConditions: String { return "TermsConditions".localized() }
    static var success: String { return "Success".localized() }
    static var emailSent: String { return "EmailSent".localized() }
    static var cancel: String { return "Cancel".localized() }
    static var retry: String { return "Retry".localized() }
    static var resetPassword: String { return "ResetPassword".localized() }
    static var twoStepTitle: String { return "TwoStepTitle".localized() }
    static var twoStepSubtitle: String { return "TwoStepSubtitle".localized() }
    static var addLater: String { return "AddLater".localized() }
    static var skip: String { return "Skip".localized() }
    static var submit: String { return "Submit".localized() }
    static var enterEmail: String { return "EnterEmail".localized() }
    static var invalidPhone: String { return "InvalidPhone".localized() }
    static var emptyNameField: String { return "EmptyNameField".localized() }
    static var noDataModification: String { return "NoDataModification".localized() }
    static var emailFieldIsEmpty: String { return "EmailFieldIsEmpty".localized() }
    static var emailIsNotValid: String { return "Please enter a valid email address.".localized() }
    static var MFARequired: String { return "MFARequired".localized() }
    static var incorrectCredentials: String { return "IncorrectCredentials".localized() }
    static var tokenExpired: String { return "TokenExpired".localized() }
    static var tokenIncorrect: String { return "TokenIncorrect".localized() }
    static var emailAlreadyUsed: String { return "EmailAlreadyUsed".localized() }
    static var invalidFields: String { return "InvalidFields".localized() }
    static var incorrectOldPassword: String { return "IncorrectOldPassword".localized() }
    static var lowPasswordComplexity: String { return "LowPasswordComplexity".localized() }
    static var passwordMatchError: String { return "PasswordMatchError".localized() }
    static var passwordChangedSuccessfully: String{ return "PasswordChangedSuccessfully".localized()}
    static var userDetailsChangedSuccessfully: String{ return "UserDetailsChangedSuccessfully".localized()}
    static var getUserDetailsWasSuccessfully: String{ return "GetUserDetailsWasSuccessfully".localized()}
    static var usePasscode: String { return "UsePasscode".localized() }
    static var welcomeMessage: String { return "WelcomeMessage".localized() }
    static var unlockWithBiometrics: String { return "UnlockWithBiometrics".localized() }
    static var useLoginCredentials: String { return "UseLoginCredentials".localized() }
    static var biometricsReason: String { return "BiometricsReason".localized() }
    static var authenticationFailed: String { return "AuthenticationFailed".localized() }
    static var hardwareUnavailable: String { return "HardwareUnavailable".localized() }
    static var authenticationTimedOut: String { return "AuthenticationTimedOut".localized() }
    static var authenticationNotEnrolled: String { return "AuthenticationNotEnrolled".localized() }
    static var authenticationContextNotSet: String { return "AuthenticationContextNotSet".localized() }
    static var authenticationCancelled: String { return "AuthenticationCancelled".localized() }
    static var authenticationInteractionFailed: String { return "AuthenticationInteractionFailed".localized() }
    static var authenticationLocked: String { return "AuthenticationLocked".localized() }
    static var biometricsSetup: String { return "AuthenticationLocked".localized() }
    static var myFiles: String { return "MyFiles".localized() }
    static var emptyFolderMessage: String { return "EmptyFolderMessage".localized() }
    static var uploadFilesMessage: String { return "UploadFilesMessage".localized() }
    static var name: String { return "Name".localized() }
    static var upload: String { return "Upload".localized() }
    static var newFolder: String { return "NewFolder".localized() }
    static var browse: String { return "Browse".localized() }
    static var photoLibrary: String { return "PhotoLibrary".localized() }
    static var waiting: String { return "Waiting".localized() }
    static var createFolder: String { return "CreateFolder".localized() }
    static var create: String { return "Create".localized() }
    static var folderName: String { return "FolderName".localized() }
    static var uploads: String { return "Uploads".localized() }
    static var delete: String { return "Delete".localized() }
    static var takePhotoOrVideo: String { return "TakePhotoOrVideo".localized() }
    static var searchFiles: String { return "SearchFiles".localized() }
    static var cameraErrorMessage: String { return "CameraErrorMessage".localized() }
    static var download: String { return "Download".localized() }
    static var copy: String { return "Copy".localized() }
    static var move: String { return "Move".localized() }
    static var publish: String { return "Publish".localized() }
    static var edit: String { return "Edit".localized() }
    static var share: String { return "Share".localized() }
    static var downloads: String { return "Downloads".localized() }
    static var cannotUpload: String { return "CannotUpload".localized() }
    static var date: String { return "Date".localized() }
    static var fileType: String { return "FileType".localized() }
    static var ascending: String { return "Ascending".localized() }
    static var descending: String { return "Descending".localized() }
    static var sortOption: String { return "%@ %@" }
    static var copyHere: String { return "CopyHere".localized() }
    static var moveHere: String { return "MoveHere".localized() }
    static var `public`: String { return "Public".localized() }
    static var relationships: String { return "Relationships".localized() }
    static var shares: String { return "Shares".localized() }
    static var member: String { return "Member".localized() }
    static var apps: String { return "Apps".localized() }
    static var manageArchives: String { return "ManageArchives".localized() }
    static var getShareLink: String { return "GetShareLink".localized() }
    static var shareLink: String { return "ShareLink".localized() }
    static var shareDescription: String { return "ShareDescription".localized() }
    static var linkCopied: String { return "LinkCopied".localized() }
    static var copyLink: String { return "\("CopyLink".localized()) \(link.lowercased())" }
    static var manageLink: String { return "\("ManageLink".localized()) \(link.lowercased())" }
    static var revokeLink: String { return "\("Revoke".localized()) \(link.lowercased())" }
    static var revoke: String { return "Revoke".localized() }
    static var link: String { return "Link".localized() }
    static var save: String { return "Save".localized() }
    static var done: String { return "Done".localized() }
    static var sharePreview: String { return "SharePreview".localized() }
    static var maxNumberUses: String { return "\("MaxNumberUses".localized()) (\(optional.lowercased()))" }
    static var expirationDate: String { return "\("ExpirationDate".localized()) (\(optional.lowercased()))" }
    static var optional: String { return "Optional".localized() }
    static var autoApprove: String { return "AutoApprove".localized() }
    static var noSharesMessage: String { return "NoSharesMessage".localized() }
    static var archiveName: String { return "ArchiveName".localized() }
    static var sharedByMe: String { return "SharedByMe".localized() }
    static var sharedWithMe: String { return "SharedWithMe".localized() }
    static var shareActionMessage: String { return "ShareActionMessage".localized() }
    static var addMember: String { return "\(add) \(member)" }
    static var add: String { return "Add".localized() }
    static var logOut: String { return "LogOut".localized() }
    static var autoApproveTooltip: String { return "AutoApproveTooltip".localized() }
    static var maxUsesTooltip: String { return "MaxUsesTooltip".localized() }
    static var expDateTooltip: String { return "ExpDateTooltip".localized() }
    static var file: String { return "File".localized() }
    static var fileCopied: String { return "\(file) \("Copied".localized().lowercased())" }
    static var fileMoved: String { return "\(file) \("Moved".localized().lowercased())" }
    static var owner: String { return "Owner".localized() }
    static var manager: String { return "Manager".localized() }
    static var curator: String { return "Curator".localized() }
    static var editor: String { return "Editor".localized() }
    static var contributor: String { return "Contributor".localized() }
    static var viewer: String { return "Viewer".localized() }
    static var none: String { return "None".localized() }
    static var ownerTooltipText: String { return "OwnerTooltipText".localized() }
    static var managerTooltipText: String { return "ManagerTooltipText".localized() }
    static var curatorTooltipText: String { return "CuratorTooltipText".localized() }
    static var editorTooltipText: String { return "EditorTooltipText".localized() }
    static var contributorTooltipText: String { return "ContributorTooltipText".localized() }
    static var viewerTooltipText: String { return "ViewerTooltipText".localized() }
    static var accessLevel: String { return "AccessLevel".localized() }
    static var memberEmail: String { return "\(member) \(email)" }
    static var security: String { return "Security".localized() }
    static var help: String { return "Help".localized() }
    static var accountInfo: String { return "AccountInfo".localized() }
    static var updatePassword: String { return "UpdatePassword".localized()}
    static var currentPassword: String { return "CurrentPassword".localized()}
    static var reTypePassword: String { return "ReTypePassword".localized()}
    static var newPassword: String { return "NewPassword".localized()}
    static var logInWithBiometrics: String { return "LogInWithBiometrics".localized()}
    static var logInWith: String { return "Log in with ".localized()}
    static var LogInFaceId: String{ return "LogInFaceId".localized()}
    static var LogInTouchId: String{ return "LogInTouchId".localized()}
    static var twoStepVerification: String { return "TwoStepVerification".localized()}
    static var sharedBy: String { return "SharedBy".localized() }
    static var fromArchive: String { return "FromArchive".localized() }
    static var requestApproval: String { return "RequestApproval".localized() }
    static var removeMember: String { return "RemoveMember".localized() }
    static var pending: String { return "Pending".localized() }
    static var requestAwaitingApproval: String { return "RequestAwaitingApproval".localized() }
    static var viewInArchive: String { return "ViewInArchive".localized() }
    static var addStorage: String { return "AddStorage".localized() }
    static var remove: String { return "Remove".localized() }
    static var accountName: String { return "AccountName".localized() }
    static var primaryEmail: String { return "PrimaryEmail".localized() }
    static var mobilePhone: String { return "MobilePhone".localized() }
    static var address: String { return "Address".localized() }
    static var city: String { return "City".localized() }
    static var stateOrRegion: String { return "StateOrRegion".localized() }
    static var postalcode: String { return "PostalCode".localized() }
    static var country: String { return "Country".localized() }
    static var saveInfo: String { return "SaveInfo".localized() }
    static var giveAGig: String { return "GiveAGig".localized() }
    static var inviteInfo: String { return "InviteInfo".localized() }
    static var sendInvite: String { return "SendInvite".localized() }
    static var resend: String { return "Resend".localized() }
    static var approve: String { return "Approve".localized() }
    static var deny: String { return "Deny".localized() }
    static var yourInvitations: String { return "YourInvitations".localized() }
    static var invitations: String { return "Invitations".localized() }
    static var send: String { return "Send".localized() }
    static var sendInvitation: String { return "SendInvitation".localized() }
    static var recipientName: String { return String.init(format: "RecipientInfo".localized(), String.name.lowercased()) }
    static var recipientEmail: String { return String.init(format: "RecipientInfo".localized(), String.email.lowercased()) }
    static var activityFeed: String { return "ActivityFeed".localized() }
    static var inviteSent: String { return "InviteSent".localized()}
    static var inviteRevoked: String { return "InviteRevoked".localized()}
    static var linkNotAvailable: String { return "LinkNotAvailable".localized()}
    static var approveShareRequest: String { return "ApproveShareRequest".localized()}
    static var denyShareRequest: String { return "DenyShareRequest".localized()}
    static var transferButtonText: String { return "Transfer".localized() }
    static var transferOwnership: String { return "Transfer Ownership".localized() }
    static var transferOwnershipInfo: String { return "Permanent Archives can only have one owner at a time. Once this is complete, your role will be changed to Curator".localized() }
    
    /// Errors
    static var errorCancelled: String { return "ErrorCancelled".localized() }
    static var errorUnknown: String { return "ErrorUnknown".localized() }
    static var errorServer: String { return "ErrorServer".localized() }
    static var downloadCancelled: String { return "DownloadCancelled".localized() }
    
    static let arrowUpCharacter: String = "\u{2191}"
    static let arrowDownCharacter: String = "\u{2193}"
    
    static let aToZ: String = "(A-Z)"
    static let zToA: String = "(Z-A)"
    static var oldest: String { return "Oldest".localized() }
    static var newest: String { return "Newest".localized() }
    static var linkSettings: String { return "LinkSettings".localized() }
}
