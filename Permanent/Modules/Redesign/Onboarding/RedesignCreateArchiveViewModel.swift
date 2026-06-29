//
//  RedesignCreateArchiveViewModel.swift
//  Permanent
//
//  Drives the redesigned create-archive flow by REUSING the existing onboarding
//  archive methods (no reimplementation of the network calls):
//    create:  OnboardingWhatsImportantViewModel.createArchive (ArchivesEndpoint.create)
//             → updateAccount(withDefaultArchiveId:)           (AccountEndpoint.update)
//             → changeArchive(_:)                              (ArchivesEndpoint.change)
//             → addRemoveTags (GOAL + WHY + type tags)         (AccountEndpoint.addRemoveTags)
//             → AuthenticationManager.saveSession()            (persist account + selectedArchive)
//
//  Data-integrity notes (prod-readiness fixes):
//   • B4: the legacy updateAccount/changeArchive mutate the session IN MEMORY only.
//     We persist with saveSession() and intentionally do NOT call reloadSession()
//     (it re-reads the stale keychain and can null the freshly-selected archive).
//   • B3: the legacy addTags swallows its API error; we call addRemoveTags directly
//     to observe the result. Tag failure is NON-FATAL (the archive is already
//     created + current) but is logged rather than silently lost.
//

import Foundation

final class RedesignCreateArchiveViewModel: ObservableObject {
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let container: OnboardingContainerViewModel
    private let onboarding: OnboardingWhatsImportantViewModel

    init() {
        container = OnboardingContainerViewModel(username: "", password: "")
        container.creatingNewArchive = true
        onboarding = OnboardingWhatsImportantViewModel(containerViewModel: container)
    }

    /// Maps the sheet's type label (an `ArchiveType.onboardingType`, e.g.
    /// "Individual", "Family History") back to the exact `ArchiveType` so the
    /// per-type tag is preserved. Falls back to `.person`.
    static func archiveType(forLabel label: String) -> ArchiveType {
        ArchiveType.allCases.first { $0.onboardingType == label } ?? .person
    }

    /// Creates the archive, sets it as default, switches to it, applies the
    /// type + GOAL + WHY tags, persists the session, then reports success.
    func createArchive(name: String,
                       typeLabel: String,
                       whyLabels: Set<String>,
                       goalLabels: Set<String>,
                       completion: @escaping (Bool) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter an archive name."
            completion(false)
            return
        }

        errorMessage = nil
        isCreating = true

        let type = Self.archiveType(forLabel: typeLabel)
        container.creatingNewArchive = true
        container.archiveName = trimmed
        container.archiveType = type
        container.selectedPath = RedesignTagMapping.goalPaths(for: goalLabels)
        container.selectedWhatsImportant = RedesignTagMapping.whatsImportant(for: whyLabels)

        onboarding.createArchive(name: trimmed, type: type.rawValue) { [weak self] archiveVO, _ in
            guard let self = self else { return }
            guard let archiveVO = archiveVO, let archiveID = archiveVO.archiveID else {
                self.finish(false, "Could not create your archive. Please try again.", completion)
                return
            }
            self.onboarding.updateAccount(withDefaultArchiveId: archiveID) { [weak self] accountVO, _ in
                guard let self = self else { return }
                guard accountVO != nil else {
                    self.finish(false, "Could not set your default archive. Please try again.", completion)
                    return
                }
                self.onboarding.changeArchive(archiveVO) { [weak self] success, _ in
                    guard let self = self else { return }
                    guard success else {
                        self.finish(false, "Could not open your new archive. Please try again.", completion)
                        return
                    }
                    // Apply tags (non-fatal), then persist the session and finish.
                    self.applyTags { [weak self] tagError in
                        guard let self = self else { return }
                        if let tagError = tagError {
                            // Non-fatal: archive exists + is current; preferences just
                            // didn't save. Surface via log (not a silent loss).
                            print("⚠️ RedesignCreateArchive: tags not saved — \(tagError)")
                        }
                        // B4: explicitly set the new archive as the account's default
                        // AND the selected archive, then persist — so a relaunch routes
                        // to the shell. (The legacy updateAccount can leave the persisted
                        // account's defaultArchiveID nil, which made relaunch fall back to
                        // the onboarding dashboard.) Do NOT reloadSession (it re-reads the
                        // keychain and can null the freshly-selected archive).
                        AuthenticationManager.shared.session?.account.defaultArchiveID = archiveVO.archiveID
                        AuthenticationManager.shared.session?.selectedArchive = archiveVO
                        AuthenticationManager.shared.saveSession()
                        self.finish(true, nil, completion)
                    }
                }
            }
        }
    }

    /// Sends the archive-type + goal + why tags via the SAME endpoint the legacy
    /// onboarding uses, but observes the result (the legacy `addTags` discards it).
    private func applyTags(_ completion: @escaping (Error?) -> Void) {
        let goalTags = container.selectedPath.compactMap { $0.tag }
        let whyTags = container.selectedWhatsImportant.compactMap { $0.tag }

        let operation = APIOperation(AccountEndpoint.addRemoveTags(
            archiveType: container.archiveType.tag,
            addGoalTags: goalTags,
            addWhyTags: whyTags,
            removeGoalTags: nil,
            removeWhyTags: nil
        ))
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json:
                completion(nil)
            default:
                completion(APIError.invalidResponse)
            }
        }
    }

    private func finish(_ success: Bool, _ message: String?, _ completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.isCreating = false
            if let message = message {
                self.errorMessage = message
            }
            completion(success)
        }
    }
}
