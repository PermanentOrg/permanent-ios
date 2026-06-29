//
//  RedesignInvitationsViewModel.swift
//  Permanent
//
//  Drives the redesigned invitation onboarding — Stage 2 (single) and Stage 3
//  (multiple) are the same widget keyed on how many invitations are pending.
//  The invitation lives as a WIDGET on the onboarding dashboard (alongside the
//  "Create your first Archive" card), not a separate full-screen flow:
//    • Accept → the membership flips pending → ok; the card stays and becomes a
//      "Go to archive" entry (the user remains on the dashboard and can still
//      create their own archive).
//    • Decline → the card is removed.
//    • Go to archive → set that archive as default + current, persist, land in
//      the shell.
//
//  There is NO dedicated inbound-invites endpoint: a pending invitation is an
//  archive membership with `status == .pending` from
//  `ArchivesEndpoint.getArchivesByAccountId`. Accept/decline reuse
//  `ArchivesEndpoint.accept`/`.decline`; "Go to archive" reuses
//  `OnboardingWhatsImportantViewModel.updateAccount`/`changeArchive` (which read
//  the session account) + `saveSession` (B4-safe: no `reloadSession`). No new
//  backend.
//

import Foundation

/// One invitation row. `id` is the archiveID. The archive payload carries the
/// archive name + the recipient's access role, but NOT an inviter name/message,
/// so the card shows archive name + role only.
struct RedesignInvitationItem: Identifiable {
    let id: Int
    let archiveName: String
    let role: String
    let initials: String
    /// The archive's avatar thumbnail, or nil when it has only a generated
    /// avatar (in which case the initials tile is shown instead).
    let thumbnailURL: String?
    /// The archive owner's name ("Invited by …"), fetched lazily via the members
    /// endpoint. Nil until resolved (or if unavailable) → the card shows
    /// "Invited as <Role>".
    var inviterName: String? = nil
    /// The archive number, used to fetch the owner/inviter.
    var archiveNbr: String? = nil
}

final class RedesignInvitationsViewModel: ObservableObject {
    @Published var items: [RedesignInvitationItem] = []
    /// IDs whose invitation has been accepted (card shows "Go to archive").
    @Published var acceptedIDs: Set<Int> = []
    /// IDs with an in-flight accept/decline/go-to-archive (card shows a spinner).
    @Published var busyIDs: Set<Int> = []
    @Published var errorMessage: String?

    private let container: OnboardingContainerViewModel
    private let onboarding: OnboardingWhatsImportantViewModel
    /// Raw pending archive data, looked up by archiveID.
    private var pending: [ArchiveVOData] = []

    init() {
        container = OnboardingContainerViewModel(username: "", password: "")
        onboarding = OnboardingWhatsImportantViewModel(containerViewModel: container)
    }

    /// More than one invitation still awaiting a decision → show "Accept all".
    var multiplePending: Bool {
        items.filter { !acceptedIDs.contains($0.id) }.count > 1
    }

    // MARK: - Load

    /// Loads pending invitations. `completion(hasPending)` lets the host know
    /// whether any invitation exists.
    func load(_ completion: ((Bool) -> Void)? = nil) {
        errorMessage = nil
        container.getAccountArchives { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = "We couldn't load your invitations."
                    completion?(false)
                    return
                }
                self.rebuild()
                completion?(!self.items.isEmpty)
            }
        }
    }

    private func rebuild() {
        pending = container.allArchivesVO.compactMap { $0.archiveVO }.filter { $0.status == .pending }
        items = pending.compactMap { data in
            guard let id = data.archiveID else { return nil }
            let name = data.fullName ?? "Archive"
            // Use the real avatar only when it isn't a generated one.
            let thumb = (data.thumbStatus != .genAvatar) ? data.preferredThumbnailURL : nil
            return RedesignInvitationItem(
                id: id,
                archiveName: name,
                role: AccessRole.roleForValue(data.accessRole).groupName,
                initials: Self.initials(from: name),
                thumbnailURL: thumb,
                inviterName: nil,
                archiveNbr: data.archiveNbr
            )
        }
        // Resolve "Invited by <owner>" for each card (best-effort; the card shows
        // "Invited as <Role>" until/unless this succeeds).
        for item in items { fetchInviter(for: item) }
    }

    /// Fetches the archive owner's name via the members endpoint and fills in the
    /// matching card's `inviterName`. Best-effort: failures (incl. not being
    /// permitted to list members of a not-yet-accepted archive) leave it nil.
    private func fetchInviter(for item: RedesignInvitationItem) {
        guard let archiveNbr = item.archiveNbr else { return }
        let operation = APIOperation(MembersEndpoint.members(archiveNbr: archiveNbr))
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }
            guard case .json(let response, _) = result,
                  let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<AccountVO>.decoder),
                  model.isSuccessful else { return }
            let members = model.results.first?.data ?? []
            let owner = members.first { AccessRole.roleForValue($0.accountVO?.accessRole) == .owner }
            guard let name = owner?.accountVO?.fullName, !name.isEmpty else { return }
            DispatchQueue.main.async {
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[idx].inviterName = name
                }
            }
        }
    }

    // MARK: - Actions

    /// Accept a single invitation (pending → ok). The card stays and flips to
    /// "Go to archive"; the user remains on the dashboard.
    func accept(_ item: RedesignInvitationItem) {
        guard let data = pending.first(where: { $0.archiveID == item.id }) else { return }
        guard !busyIDs.contains(item.id), !acceptedIDs.contains(item.id) else { return }
        busyIDs.insert(item.id)
        errorMessage = nil
        acceptOperation(data) { [weak self] ok in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.busyIDs.remove(item.id)
                if ok {
                    self.acceptedIDs.insert(item.id)
                } else {
                    self.errorMessage = "We couldn't accept this invitation. Please try again."
                }
            }
        }
    }

    /// Accept every still-pending invitation (Stage 3 convenience).
    func acceptAll() {
        for item in items where !acceptedIDs.contains(item.id) {
            accept(item)
        }
    }

    /// Decline a single invitation → remove its card.
    func decline(_ item: RedesignInvitationItem) {
        guard let data = pending.first(where: { $0.archiveID == item.id }) else { return }
        guard !busyIDs.contains(item.id) else { return }
        busyIDs.insert(item.id)
        errorMessage = nil
        let operation = APIOperation(ArchivesEndpoint.decline(archiveVO: data))
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.busyIDs.remove(item.id)
                switch result {
                case .json(let response, _):
                    let model: APIResults<NoDataModel>? = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder)
                    if model?.isSuccessful == true {
                        self.pending.removeAll { $0.archiveID == item.id }
                        self.items.removeAll { $0.id == item.id }
                        self.acceptedIDs.remove(item.id)
                    } else {
                        self.errorMessage = "We couldn't decline this invitation. Please try again."
                    }
                default:
                    self.errorMessage = "We couldn't decline this invitation. Please try again."
                }
            }
        }
    }

    /// Enter an accepted archive: switch the current archive to it (and, in the
    /// onboarding context, set it as the account default so relaunch routes to the
    /// shell), persist, then `onFinished`.
    ///
    /// - `setAsDefault`: onboarding passes `true` (the user has no default yet, so
    ///   one must be set to leave onboarding); the shell passes `false` (the user
    ///   already has a default — "Go to archive" just switches the current one).
    func goToArchive(_ item: RedesignInvitationItem, setAsDefault: Bool = true, onFinished: @escaping () -> Void) {
        guard let data = pending.first(where: { $0.archiveID == item.id }), let archiveID = data.archiveID else { return }
        guard !busyIDs.contains(item.id) else { return }
        busyIDs.insert(item.id)
        errorMessage = nil

        let switchArchive: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.onboarding.changeArchive(data) { [weak self] success, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.busyIDs.remove(item.id)
                    guard success else {
                        self.errorMessage = "We couldn't open your archive. Please try again."
                        return
                    }
                    if setAsDefault {
                        AuthenticationManager.shared.session?.account.defaultArchiveID = archiveID
                    }
                    // Sets selectedArchive + saves + posts didChangeArchiveNotification
                    // so the shell (dashboard + hosted file manager) refreshes.
                    // (No reloadSession — it can null the freshly-selected archive.)
                    AuthenticationManager.shared.updateSelectedArchive(data)
                    onFinished()
                }
            }
        }

        if setAsDefault {
            onboarding.updateAccount(withDefaultArchiveId: archiveID) { [weak self] accountVO, _ in
                guard let self = self else { return }
                guard accountVO != nil else {
                    DispatchQueue.main.async {
                        self.busyIDs.remove(item.id)
                        self.errorMessage = "We couldn't set your default archive. Please try again."
                    }
                    return
                }
                switchArchive()
            }
        } else {
            switchArchive()
        }
    }

    // MARK: - Helpers

    private func acceptOperation(_ data: ArchiveVOData, _ completion: @escaping (Bool) -> Void) {
        let operation = APIOperation(ArchivesEndpoint.accept(archiveVO: data))
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                let model: APIResults<NoDataModel>? = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder)
                completion(model?.isSuccessful == true)
            default:
                completion(false)
            }
        }
    }

    static func initials(from name: String) -> String {
        let stripped = name
            .replacingOccurrences(of: "The ", with: "")
            .replacingOccurrences(of: " Archive", with: "")
            .trimmingCharacters(in: .whitespaces)
        let letters = stripped.split(separator: " ").prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "?" : result
    }
}
