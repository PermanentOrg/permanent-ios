//
//  RedesignDashboardView.swift
//  Permanent
//
//  Redesigned onboarding-dashboard (Frame C). States:
//    .loading (Frame A) → auto-advances (~1.4s) to .loaded.
//    .loaded shows the greeting + "Let's begin your archive" card + the
//      "What's important to you?" card + the "Chart your path to success" goals
//      card + a "You're all caught up." footer.
//
//  Wiring (reuses the existing onboarding endpoints):
//    - "Create your first Archive" → Frame D sheet → `onCreateArchive`. The
//      "What's important" (why) AND "Chart your path" (goals) selections ride
//      along as tags on the create's single addRemoveTags call (the backend
//      rejects tags before an archive/type exists, so they're sent at create —
//      exactly like the legacy finishOnboard). On success `onArchiveCreated`
//      runs (lands in the file manager).
//    - The goals card's "Save goals" / "Remind me later" simply confirm/dismiss
//      the card locally; the selection persists for the create call.
//  Defaults are no-ops so previews are safe.
//

import SwiftUI

enum RedesignDashboardState {
    case loading
    case loaded
}

struct RedesignDashboardView: View {
    var showsCards: Bool = true

    /// Performs the real archive creation. `(name, typeLabel, whyLabels, goalLabels, completion)`
    /// where completion is `(success, errorMessage)`. Default no-op succeeds (previews).
    var onCreateArchive: (_ name: String, _ typeLabel: String, _ whyLabels: Set<String>, _ goalLabels: Set<String>, _ completion: @escaping (Bool, String?) -> Void) -> Void = { _, _, _, _, completion in completion(true, nil) }

    /// Invoked after a successful creation (e.g. land in the file manager).
    var onArchiveCreated: () -> Void = {}

    /// Optional invitation widget (Stage 2/3) rendered above the "Let's begin
    /// your archive" card. `nil` (the default) renders nothing.
    var invitationsSection: AnyView? = nil

    /// Opens the account menu from the header's profile button. This is the
    /// no-archive onboarding state, matching Android: the full account/settings
    /// menu (which simply shows no archives). `nil` (previews) → inert button.
    var onProfile: (() -> Void)? = nil

    @State private var state: RedesignDashboardState
    @State private var showCreateSheet = false
    @State private var isCreating = false
    @State private var createError: String?
    @State private var selectedImportant: Set<String> = []
    @State private var selectedGoals: Set<String> = ["Share privately", "Build an archive with someone"]
    @State private var showImportantCard = true
    @State private var showGoalsCard = true
    @State private var caughtUpRevealed = false

    init(initialState: RedesignDashboardState = .loading,
         showsCards: Bool = true,
         invitationsSection: AnyView? = nil,
         onProfile: (() -> Void)? = nil,
         onCreateArchive: @escaping (_ name: String, _ typeLabel: String, _ whyLabels: Set<String>, _ goalLabels: Set<String>, _ completion: @escaping (Bool, String?) -> Void) -> Void = { _, _, _, _, completion in completion(true, nil) },
         onArchiveCreated: @escaping () -> Void = {}) {
        _state = State(initialValue: initialState)
        self.showsCards = showsCards
        self.invitationsSection = invitationsSection
        self.onProfile = onProfile
        self.onCreateArchive = onCreateArchive
        self.onArchiveCreated = onArchiveCreated
    }

    /// Greeting name: session's first name if available, else "Robert".
    private var firstName: String {
        if let full = AuthenticationManager.shared.session?.account?.fullName,
           let first = full.split(separator: " ").first, !first.isEmpty {
            return String(first)
        }
        return "Robert"
    }

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
        VStack(spacing: 0) {
            // No-archive onboarding state: no drawer (left hamburger hidden); the
            // profile button opens the account menu (matches Android).
            RedesignDashboardHeader(onProfile: { onProfile?() }, showsMenu: false)

            switch state {
            case .loading:
                ScrollView(showsIndicators: false) {
                    RedesignSkeletonView()
                        .padding(RedesignSpacing.contentPadding)
                }
            case .loaded:
                ScrollView(showsIndicators: false) {
                    VStack(spacing: RedesignSpacing.sectionGap) {
                        RedesignGreetingRow(firstName: firstName)
                        if showsCards {
                            // Stage 2/3: invitation widget above the create card
                            // (renders nothing when there are no invitations).
                            invitationsSection
                            letsBeginCard
                            if showImportantCard {
                                whatsImportantCard
                            }
                            if showGoalsCard {
                                goalsCard
                            }
                            // Always the last item, regardless of the cards above.
                            caughtUpFooter
                        }
                    }
                    .padding(RedesignSpacing.contentPadding)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RedesignColor.whiteGray)
        .ignoresSafeArea(edges: .bottom)
        .task {
            guard state == .loading else { return }
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                state = .loaded
            }
        }
        .fullScreenCover(isPresented: $showCreateSheet) {
            RedesignCreateArchiveSheet(
                isCreating: isCreating,
                errorMessage: createError,
                onClose: {
                    guard !isCreating else { return }
                    showCreateSheet = false
                },
                onCreate: { name, typeLabel in
                    createError = nil
                    isCreating = true
                    onCreateArchive(name, typeLabel, selectedImportant, selectedGoals) { success, message in
                        isCreating = false
                        if success {
                            showCreateSheet = false
                            onArchiveCreated()
                        } else {
                            createError = message ?? "Could not create your archive. Please try again."
                        }
                    }
                }
            )
            .background(BackgroundClearView())
        }
    }

    // MARK: - "Let's begin your archive" card (Frame C)

    private var letsBeginCard: some View {
        RedesignWidgetCard {
            VStack(spacing: 48) {
                RedesignGradientTitle(
                    lines: [
                        RedesignTitleLine([RedesignTitleRun("Let's begin")]),
                        RedesignTitleLine([
                            RedesignTitleRun("your "),
                            RedesignTitleRun("archive", italic: true)
                        ])
                    ],
                    // Figma "Let's begin your archive" uses the dark-blue gradient
                    // (#131B4A→#364493), not the purple-orange one.
                    gradient: RedesignGradient.heroTitleDarkBlue
                )
                .frame(width: 260)

                VStack(spacing: 48) {
                    Text("A permanent home for the memories,\ndocuments and stories that matter most — preserved for generations to come.")
                        .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                        .lineSpacing(24 - 14)
                        .multilineTextAlignment(.center)
                        .foregroundColor(RedesignColor.blue600)
                        .fixedSize(horizontal: false, vertical: true)

                    RedesignPrimaryButton(title: "Create your first Archive") {
                        showCreateSheet = true
                    }

                    lockReassurance
                }
            }
            .padding(.top, 48)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
        }
    }

    /// Footer lock reassurance (Frame C): centered, gap 8.
    private var lockReassurance: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white)
                Image(systemName: "lock")
                    .font(.system(size: 16))
                    .foregroundColor(RedesignColor.success500)
            }
            .frame(width: 24, height: 24)

            (Text("Private by default.")
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 12))
             + Text(" Nothing is published or shared until you choose to.")
                .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12)))
            .multilineTextAlignment(.center)
            .lineSpacing(16 - 12)
            .foregroundColor(RedesignColor.blue600)
        }
    }

    // MARK: - "What's important to you?" card (Frame C)

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

                Rectangle()
                    .fill(RedesignColor.whiteGray)
                    .frame(height: 1)

                importantFooter
            }
            .padding(24)
        }
    }

    /// "Remind me later" / "Save" footer for the "What's important to you?" card —
    /// the same affordance as the goals card, recolored for the white card (muted
    /// blue link + dark-blue primary, matching the card's selected-chip accent).
    /// Both collapse the card; the selection persists for the create call.
    private var importantFooter: some View {
        HStack {
            Button(action: dismissImportantCard) {
                Text("Remind me later")
                    .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                    .foregroundColor(RedesignColor.blue400)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: dismissImportantCard) {
                Text("Save")
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                    .foregroundColor(RedesignColor.darkBlue)
            }
            .buttonStyle(.plain)
        }
    }

    private func dismissImportantCard() {
        withAnimation(.easeInOut(duration: 0.25)) { showImportantCard = false }
    }

    // MARK: - "Chart your path to success" goals card (Frame C)

    private var goalsCard: some View {
        RedesignGoalsCard(
            goals: goalLabels,
            selected: $selectedGoals,
            onRemindLater: { dismissGoalsCard() },
            onSave: { dismissGoalsCard() }
        )
    }

    /// "Save goals" / "Remind me later" both collapse the card; the selection is
    /// retained and applied when the archive is created.
    private func dismissGoalsCard() {
        withAnimation(.easeInOut(duration: 0.25)) { showGoalsCard = false }
    }

    /// "You're all caught up." — always the last item. It springs into view the
    /// first time the user scrolls it onto screen (fades up + un-blurs + scales
    /// from the bottom), then stays. An invisible base text reserves the layout
    /// slot so the scroll detector reads the true (untransformed) frame, while the
    /// overlay carries the reveal transforms.
    private var caughtUpFooter: some View {
        caughtUpText
            .opacity(0)
            .overlay(
                caughtUpText
                    .opacity(caughtUpRevealed ? 1 : 0)
                    .scaleEffect(caughtUpRevealed ? 1 : 0.6, anchor: .bottom)
                    .blur(radius: caughtUpRevealed ? 0 : 8)
                    .offset(y: caughtUpRevealed ? 0 : 28)
            )
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { topY in
                            revealCaughtUpIfNeeded(topY: topY)
                        }
                }
            )
            .padding(.top, 8)
    }

    private var caughtUpText: some View {
        Text("You're all caught up.")
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
            .foregroundStyle(RedesignGradient.caughtUp)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// One-shot: reveal once the footer's top edge has scrolled ~40pt above the
    /// screen bottom (i.e. it has actually come into view). Stays revealed after.
    private func revealCaughtUpIfNeeded(topY: CGFloat) {
        guard !caughtUpRevealed else { return }
        guard topY < UIScreen.main.bounds.height - 40 else { return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
            caughtUpRevealed = true
        }
    }
}

/// Makes the fullScreenCover host transparent so the sheet's own dimmed scrim
/// (Frame D) shows through over the dashboard.
private struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview("A · Loading") {
    RedesignDashboardView(initialState: .loading)
}

#Preview("C · Loaded") {
    RedesignDashboardView(initialState: .loaded)
}
