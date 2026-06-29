//
//  RedesignHomeDashboardView.swift
//  Permanent
//
//  Stage 6 — the POPULATED "My Dashboard" tab (returning user). The shared
//  RedesignShellHeader is rendered by RedesignAppShellView above both tabs, so
//  this view starts at the greeting. Layout:
//    ScrollView {
//      RedesignGreetingRow(firstName:)
//      RedesignArchivesWidget(...)         ← real archives + "Create an Archive"
//      "What's important to you?" card     (reused markup from the onboarding dash)
//      RedesignGoalsCard                   ("Chart your path to success")
//      "You're all caught up." footer
//    }
//
//  Data: `RedesignHomeViewModel.load()` (real ArchivesViewModel.getAccountArchives).
//  Create: presents `RedesignCreateArchiveSheet` wired to
//  `RedesignCreateArchiveViewModel`; on success → reload archives + dismiss.
//  Row tap: `RedesignHomeViewModel.selectArchive` (ArchivesViewModel.changeArchive).
//
//  Only reachable when `DashboardRedesign.isEnabled`.
//

import SwiftUI

struct RedesignHomeDashboardView: View {
    @StateObject private var home = RedesignHomeViewModel()
    @StateObject private var createVM = RedesignCreateArchiveViewModel()
    @StateObject private var invitesVM = RedesignInvitationsViewModel()

    @Environment(\.scenePhase) private var scenePhase
    @State private var showCreateSheet = false
    @State private var selectedImportant: Set<String> = []
    @State private var selectedGoals: Set<String> = ["Share privately", "Build an archive with someone"]
    @State private var showGoalsCard = true

    private let chipLabels = [
        "Digital preservation", "Collaboration", "Family history",
        "Secure digital storage", "Supporting a nonprofit", "Business needs"
    ]

    private let goalLabels = [
        "Publish a legacy", "Plan my digital legacy", "Share privately",
        "Preserve memories", "Digitize my materials",
        "Build an archive with someone", "Organize my materials"
    ]

    var body: some View {
        // The shared shell header (RedesignShellHeader) is now rendered ONCE by
        // RedesignAppShellView above both tabs, so this view no longer renders
        // its own RedesignDashboardHeader.
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: RedesignSpacing.sectionGap) {
                    RedesignGreetingRow(firstName: home.firstName)

                    // Stage 2/3: pending invitations also surface here for returning
                    // users (who are past onboarding). Renders nothing when none.
                    // "Go to archive" switches the current archive (without changing
                    // the account default), then reloads the list.
                    RedesignInvitationWidget(
                        vm: invitesVM,
                        onGoToArchive: { invitesVM.load() },
                        setsDefaultOnGoToArchive: false
                    )

                    RedesignArchivesWidget(
                        archives: home.archives,
                        onSelect: { item in
                            home.selectArchive(item) { _ in
                                // Stay on the dashboard after switching.
                                // TODO: optionally jump to the Files tab here.
                            }
                        },
                        onCreate: { showCreateSheet = true }
                    )

                    whatsImportantCard

                    if showGoalsCard {
                        goalsCard
                        caughtUpFooter
                    }
                }
                .padding(RedesignSpacing.contentPadding)
                // Leave room for the floating bottom-nav pill.
                .padding(.bottom, 96)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RedesignColor.whiteGray)
        .ignoresSafeArea(edges: .bottom)
        .task {
            home.load()
            invitesVM.load()
        }
        // Re-check for new invitations (and refresh archives) when the app returns
        // to the foreground — so an invite sent while the app was open shows up.
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                invitesVM.load()
                home.load()
            }
        }
        .fullScreenCover(isPresented: $showCreateSheet) {
            RedesignCreateArchiveSheet(
                isCreating: createVM.isCreating,
                errorMessage: createVM.errorMessage,
                onClose: {
                    guard !createVM.isCreating else { return }
                    showCreateSheet = false
                },
                onCreate: { name, typeLabel in
                    createVM.createArchive(
                        name: name,
                        typeLabel: typeLabel,
                        whyLabels: selectedImportant,
                        goalLabels: selectedGoals
                    ) { success in
                        if success {
                            showCreateSheet = false
                            home.load()
                        }
                    }
                }
            )
            .background(BackgroundClearHostView())
        }
    }

    // MARK: - "What's important to you?" card (reused from the onboarding dash)

    private var whatsImportantCard: some View {
        RedesignWidgetCard {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle().fill(RedesignColor.whiteGray)
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(RedesignColor.tangerine)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("What's important to you?")
                            .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                            .foregroundColor(RedesignColor.darkBlue)
                            .frame(height: 24)
                        Text("We'll use this to guide your next steps")
                            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
                            .foregroundColor(RedesignColor.blue600)
                            .frame(height: 16)
                    }
                    Spacer(minLength: 0)
                }

                Rectangle()
                    .fill(RedesignColor.whiteGray)
                    .frame(height: 1)

                RedesignChipWrap(labels: chipLabels, interactive: true, selection: $selectedImportant)
            }
            .padding(24)
        }
    }

    // MARK: - "Chart your path to success" goals card (reused)

    private var goalsCard: some View {
        RedesignGoalsCard(
            goals: goalLabels,
            selected: $selectedGoals,
            onRemindLater: { dismissGoalsCard() },
            onSave: { dismissGoalsCard() }
        )
    }

    private func dismissGoalsCard() {
        withAnimation(.easeInOut(duration: 0.25)) { showGoalsCard = false }
    }

    private var caughtUpFooter: some View {
        Text("You're all caught up.")
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
            .foregroundStyle(RedesignGradient.caughtUp)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
    }
}

/// Makes the fullScreenCover host transparent so the create sheet's own dimmed
/// scrim shows through over the dashboard (mirrors the onboarding dash helper).
private struct BackgroundClearHostView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    RedesignHomeDashboardView()
}
