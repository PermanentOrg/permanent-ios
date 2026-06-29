//
//  RedesignInvitationsView.swift
//  Permanent
//
//  Stage 2 (single) + Stage 3 (multiple) invitation onboarding rendered as a
//  connected card stack on the onboarding dashboard (Figma node 25398:54756):
//    • the big "You've been invited!" Gyst gradient hero sits on the first card,
//    • each invitation is its own segment (archive thumbnail or initials tile +
//      "The <Archive>" + "Invited as <Role>" + Decline / Accept),
//    • a "What's this?" caption closes the stack.
//  Accept flips the segment in place to "Go to archive"; Decline removes it; the
//  "Create your first Archive" card sits below this widget. Only reachable when
//  DashboardRedesign.isEnabled.
//
//  Note: the mobile getAllArchives payload (`ArchiveVOData`) does not include the
//  inviter's name, so the subtitle reads "Invited as <Role>" rather than the
//  web's "Invited by <Name> as <Role>".
//

import SwiftUI

/// The invitation widget shown on the onboarding dashboard. Renders nothing when
/// there are no invitations, so the host can include it unconditionally.
struct RedesignInvitationWidget: View {
    @ObservedObject var vm: RedesignInvitationsViewModel
    /// "Go to archive" → land in the shell (onboarding) or refresh (in-shell).
    var onGoToArchive: () -> Void
    /// Whether "Go to archive" sets the archive as the account default. Onboarding
    /// (no default yet) → true; the shell Dashboard (already has a default) → false.
    var setsDefaultOnGoToArchive: Bool = true

    var body: some View {
        if vm.items.isEmpty {
            EmptyView()
        } else if let error = vm.errorMessage {
            VStack(spacing: 8) {
                Text(error)
                    .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
                    .foregroundColor(RedesignColor.error500)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                invitationCard
            }
        } else {
            invitationCard
        }
    }

    // MARK: - Card (hero + invitation(s) + "What's this?" — all in ONE card)

    private var invitationCard: some View {
        VStack(spacing: 0) {
            hero
                .padding(.top, 48)

            ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                if index == 0 {
                    invitationContent(item)
                        .padding(.top, 48)
                } else {
                    cardDivider.padding(.top, 24)
                    invitationContent(item).padding(.top, 24)
                }
            }

            // "What's this?" lives INSIDE this card (no separate card / separator).
            cardDivider.padding(.top, 24)
            whatsThisText.padding(.top, 24)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .widgetDropShadow()
    }

    private var cardDivider: some View {
        Rectangle().fill(RedesignColor.whiteGray).frame(height: 1)
    }

    private var hero: some View {
        RedesignGradientTitle(
            lines: [
                RedesignTitleLine([RedesignTitleRun("You've been")]),
                RedesignTitleLine([RedesignTitleRun("invited!", italic: true)])
            ],
            gradient: RedesignGradient.heroTitlePurpleOrange
        )
        .frame(width: 260)
    }

    private func invitationContent(_ item: RedesignInvitationItem) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                media(item)
                VStack(spacing: 4) {
                    attributedArchiveName(item.archiveName)
                        .lineSpacing(24 - 14)
                        .multilineTextAlignment(.center)
                    subtitle(item)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            actionRow(item)
        }
    }

    // MARK: - Media (96 thumbnail when present, else 40 initials tile)

    @ViewBuilder
    private func media(_ item: RedesignInvitationItem) -> some View {
        if let urlString = item.thumbnailURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(RedesignColor.whiteGray)
                default:
                    bigTile(item.initials)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            smallTile(item.initials)
        }
    }

    /// 96×96 gradient fallback (when an archive has a thumbnail URL but it fails).
    private func bigTile(_ initials: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RedesignGradient.iconPurpleOrange)
            Text(initials)
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 28))
                .foregroundColor(.white)
        }
        .frame(width: 96, height: 96)
    }

    /// 40×40 gradient initials tile with the archive-switcher notch (no thumbnail).
    private func smallTile(_ initials: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(RedesignGradient.iconPurpleOrange)
            VStack {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 16, height: 2)
                    .padding(.top, 6)
                Spacer()
            }
            Text(initials)
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 12))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
    }

    // MARK: - Text

    /// "The **<middle>** Archive" — all in Permanent Blue/900, the middle word in Medium.
    private func attributedArchiveName(_ fullName: String) -> Text {
        let color = RedesignColor.darkBlue
        // Always render "The <name> Archive": strip any existing "The"/"Archive"
        // wrapper first so we never double it (e.g. "Sport" → "The Sport Archive";
        // "The Astoria Public Library Archive" stays as-is).
        var core = fullName.trimmingCharacters(in: .whitespaces)
        if core.lowercased().hasPrefix("the ") {
            core = String(core.dropFirst(4))
        }
        if core.lowercased().hasSuffix(" archive") {
            core = String(core.dropLast(" archive".count))
        }
        core = core.trimmingCharacters(in: .whitespaces)

        return Text("The ")
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
            .foregroundColor(color)
        + Text(core)
            .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
            .foregroundColor(color)
        + Text(" Archive")
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
            .foregroundColor(color)
    }

    /// "Invited by **<Name>** as <Role>" (Figma) in Permanent Blue/400 — the name
    /// in Medium. Falls back to "Invited as **<Role>**" until/unless the owner
    /// name resolves (or if it's unavailable).
    private func subtitle(_ item: RedesignInvitationItem) -> Text {
        let color = RedesignColor.blue400
        let regularName = FontName.usualRegular.rawValue
        let mediumName = FontName.usualMedium.rawValue

        if let inviter = item.inviterName, !inviter.isEmpty {
            return Text("Invited by ").font(.custom(regularName, fixedSize: 12)).foregroundColor(color)
                + Text(inviter).font(.custom(mediumName, fixedSize: 12)).foregroundColor(color)
                + Text(" as ").font(.custom(regularName, fixedSize: 12)).foregroundColor(color)
                + Text(item.role).font(.custom(regularName, fixedSize: 12)).foregroundColor(color)
        } else {
            return Text("Invited as ").font(.custom(regularName, fixedSize: 12)).foregroundColor(color)
                + Text(item.role).font(.custom(mediumName, fixedSize: 12)).foregroundColor(color)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private func actionRow(_ item: RedesignInvitationItem) -> some View {
        if vm.busyIDs.contains(item.id) {
            ProgressView()
                .tint(RedesignColor.darkBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        } else if vm.acceptedIDs.contains(item.id) {
            RedesignPrimaryButton(title: "Go to archive") {
                vm.goToArchive(item, setAsDefault: setsDefaultOnGoToArchive, onFinished: onGoToArchive)
            }
        } else {
            HStack(spacing: 16) {
                Button { vm.decline(item) } label: {
                    Text("Decline")
                        .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                        .foregroundColor(RedesignColor.error500)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(RedesignColor.whiteGray)
                        )
                }
                .buttonStyle(.plain)

                Button { vm.accept(item) } label: {
                    Text("Accept")
                        .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(RedesignColor.success500)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - "What's this?" caption (inside the invitation card)

    private var whatsThisText: some View {
        (Text("What's this? ")
            .font(.custom(FontName.usualMedium.rawValue, fixedSize: 12))
            .foregroundColor(RedesignColor.blue600)
         + Text("A Permanent archive is the collection of digital materials about an individual, family or group, or organizational entity.")
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
            .foregroundColor(RedesignColor.blue600))
        .lineSpacing(16 - 12)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

/// Onboarding root for a logged-in user without a default archive. Shows the
/// create-archive dashboard, with the invitation widget rendered at the top when
/// the account has pending invitations (Stage 2/3). Accept flips a card to
/// "Go to archive" in place; declining removes it; the user can still create
/// their own. Either "Go to archive" or "Create" ends in `onFinished` (the shell).
struct RedesignOnboardingRootView: View {
    let onFinished: () -> Void
    /// Opens the account menu from the header's profile button (matches Android).
    /// When nil the profile button is inert.
    var onProfile: (() -> Void)? = nil

    @StateObject private var invitesVM = RedesignInvitationsViewModel()
    @StateObject private var createVM = RedesignCreateArchiveViewModel()

    var body: some View {
        RedesignDashboardView(
            invitationsSection: AnyView(
                RedesignInvitationWidget(vm: invitesVM, onGoToArchive: onFinished)
            ),
            onProfile: onProfile,
            onCreateArchive: { name, typeLabel, whyLabels, goalLabels, completion in
                createVM.createArchive(name: name,
                                       typeLabel: typeLabel,
                                       whyLabels: whyLabels,
                                       goalLabels: goalLabels) { success in
                    completion(success, createVM.errorMessage)
                }
            },
            onArchiveCreated: onFinished
        )
        .task { invitesVM.load() }
    }
}

#Preview("Invitation widget") {
    let vm = RedesignInvitationsViewModel()
    vm.items = [
        RedesignInvitationItem(id: 1, archiveName: "The Astoria Public Library Archive", role: "Viewer", initials: "AP", thumbnailURL: "https://picsum.photos/200"),
        RedesignInvitationItem(id: 2, archiveName: "The Family Farm Archive", role: "Owner", initials: "FF", thumbnailURL: nil)
    ]
    return ScrollView {
        RedesignInvitationWidget(vm: vm, onGoToArchive: {})
            .padding(24)
    }
    .background(RedesignColor.whiteGray)
}
