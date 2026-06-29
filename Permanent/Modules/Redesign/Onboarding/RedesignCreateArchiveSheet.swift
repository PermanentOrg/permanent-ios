//
//  RedesignCreateArchiveSheet.swift
//  Permanent
//
//  Frame D — onboarding step 1 modal. Bottom sheet over a dimmed scrim:
//  header (centered title + close), dark-blue gradient serif hero, an
//  archive-type picker field, an archive-name TextField, a lock reassurance
//  row, and a "Create Archive" primary button.
//
//  `onCreate(name, typeLabel)` is wired to the existing archive-create
//  choreography by the host (RedesignOnboardingEntry). `isCreating` shows a
//  spinner on the button; `errorMessage` surfaces a failure inline.
//

import SwiftUI

struct RedesignCreateArchiveSheet: View {
    var isCreating: Bool = false
    var errorMessage: String? = nil
    var onClose: () -> Void = {}
    /// (archiveName, archiveTypeLabel)
    var onCreate: (_ name: String, _ type: String) -> Void = { _, _ in }

    @State private var archiveName: String = ""
    @State private var selectedType: ArchiveType = .person
    @State private var showTypePicker = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrim over the (peeking) dashboard.
            RedesignGradient.scrim
                .ignoresSafeArea()
                .onTapGesture { if !isCreating { onClose() } }

            sheet
                .transition(.move(edge: .bottom))
        }
        .background(Color.clear)
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            body0
        }
        .background(RedesignColor.whiteGray)
        .clipShape(SheetTopRoundedShape(radius: RedesignSpacing.sheetTopRadius))
        .shadow(color: Color.black.opacity(0.16), radius: 32, x: 0, y: -16)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showTypePicker) {
            RedesignArchiveTypePicker(
                selected: $selectedType,
                onClose: { showTypePicker = false }
            )
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("Create your first Archive")
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 16))
                .tracking(-0.16)
                .foregroundColor(RedesignColor.darkBlue)
                .frame(height: 24)

            HStack {
                // Hidden 48×48 slot keeps the title centered.
                Color.clear.frame(width: 48, height: 48)
                Spacer()
                Button(action: { if !isCreating { onClose() } }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(RedesignColor.darkBlue)
                        .frame(width: 44, height: 44)
                        .redesignDismissGlass()
                }
                .frame(width: 48, height: 48)
                .opacity(isCreating ? 0.4 : 1)
            }
        }
        .padding(14)
        .background(RedesignColor.whiteGray)
    }

    // MARK: Body

    private var body0: some View {
        VStack(spacing: 16) {
            // 1. Hero title block, padding v24, dark-blue gradient.
            RedesignGradientTitle(
                lines: [
                    RedesignTitleLine([RedesignTitleRun("What do you plan")]),
                    RedesignTitleLine([
                        RedesignTitleRun("to "),
                        RedesignTitleRun("capture", italic: true),
                        RedesignTitleRun(" and")
                    ]),
                    RedesignTitleLine([
                        RedesignTitleRun("preserve?", italic: true)
                    ])
                ],
                gradient: RedesignGradient.heroTitleDarkBlue
            )
            .padding(.vertical, 24)

            typePickerField
            archiveNameField
            reassuranceRow

            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
                    .foregroundColor(RedesignColor.error500)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 0)

            RedesignPrimaryButton(
                title: "Create Archive",
                gradient: RedesignGradient.primaryButtonD,
                isLoading: isCreating
            ) {
                onCreate(archiveName, selectedType.onboardingType)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(RedesignColor.whiteGray)
    }

    // MARK: Fields

    private var typePickerField: some View {
        Button {
            if !isCreating { showTypePicker = true }
        } label: {
            HStack(spacing: 16) {
                iconBadge(selectedType.redesignSFSymbol)
                Text(selectedType.onboardingType)
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                    .foregroundColor(RedesignColor.darkBlue)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 16))
                    .foregroundColor(RedesignColor.blue300)
            }
            .padding(16)
            .frame(height: 72)
            .background(fieldBackground)
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
    }

    private var archiveNameField: some View {
        HStack(spacing: 16) {
            iconBadge("archivebox")
            TextField("", text: $archiveName, prompt:
                Text("Archive name...")
                    .foregroundColor(RedesignColor.blue400)
            )
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
            .foregroundColor(RedesignColor.darkBlue)
            .focused($nameFocused)
            .disabled(isCreating)

            if !archiveName.isEmpty {
                Button {
                    archiveName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(RedesignColor.blue100)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(minHeight: 56)
        .background(fieldBackground)
    }

    private var reassuranceRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "lock")
                .font(.system(size: 16))
                .foregroundColor(RedesignColor.success500)
                .frame(width: 40, height: 40)
            Text("Nothing is published or shared until you choose to.")
                .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
                .lineSpacing(16 - 12)
                .foregroundColor(RedesignColor.blue400)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Helpers

    private func iconBadge(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundStyle(RedesignGradient.iconPurpleOrange)
            .frame(width: 40, height: 40)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: RedesignSpacing.buttonRadius, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: RedesignSpacing.buttonRadius, style: .continuous)
                    .stroke(RedesignColor.blue50, lineWidth: 1)
            )
    }
}

/// Rounds only the top corners (Frame D sheet, radius 38).
struct SheetTopRoundedShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

#Preview("D · Create Archive") {
    ZStack {
        RedesignColor.darkBlue.ignoresSafeArea()
        RedesignCreateArchiveSheet()
    }
}
