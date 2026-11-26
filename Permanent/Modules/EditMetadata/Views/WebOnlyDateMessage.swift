//
//  WebOnlyDateMessage.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2026.
//

import SwiftUI
import UIKit

/// The "Coming soon to mobile" panel every date door shows for a complex date, in place of the date sheet.
/// It sits at the bottom over a scrim and keeps its size: a drag moves it down only, and a long one closes it.
/// The card slides in from the bottom edge and back out, or fades with Reduce Motion; the scrim fades.
struct WebOnlyDateMessage: View {
    let message: String
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    @State private var isShown = false
    @State private var isClosing = false
    @State private var cardHeight: CGFloat = 0

    static let cornerRadius: CGFloat = 38
    private static let padding: CGFloat = 32
    /// A drag down past this many points, or a quick flick down, closes the panel.
    static let closingDrag: CGFloat = 120
    static let slideDuration: TimeInterval = 0.3
    /// On a phone with a home indicator, its safe area stands in for the bottom padding.
    private static var bottomPadding: CGFloat {
        let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first { $0.isKeyWindow }
        return (window?.safeAreaInsets.bottom ?? 0) > 0 ? 0 : padding
    }

    var body: some View {
        GeometryReader { proxy in
            let hidden = Self.hiddenCard(reduceMotion: reduceMotion, cardHeight: cardHeight, bottomInset: proxy.safeAreaInsets.bottom)
            ZStack(alignment: .bottom) {
                Gradient.darkLightBlueGradient
                    .opacity(isShown ? 0.48 : 0)
                    .ignoresSafeArea()
                    .onTapGesture(perform: dismiss)
                    .accessibilityHidden(true)
                card
                    .offset(y: isShown ? dragOffset : hidden.offset)
                    .opacity(isShown ? 1 : hidden.opacity)
                    .background(GeometryReader { card in
                        Color.clear
                            .onAppear { measured(card.size.height) }
                            .onChange(of: card.size.height) { measured($0) }
                    })
                    .gesture(drag)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// Where the card waits: just below the bottom edge, so it shows from the first frame as the scrim fades in.
    /// It stays clear until its height is known, and with Reduce Motion it waits in place and only fades.
    static func hiddenCard(reduceMotion: Bool, cardHeight: CGFloat, bottomInset: CGFloat) -> (offset: CGFloat, opacity: Double) {
        guard cardHeight > 0, !reduceMotion else { return (0, 0) }
        return (cardHeight + bottomInset, 1)
    }

    /// The entrance waits for the card's height, then starts one turn later from the hidden place just drawn.
    private func measured(_ height: CGFloat) {
        let isFirst = cardHeight == 0 && height > 0
        cardHeight = height
        guard isFirst else { return }
        DispatchQueue.main.async {
            guard !isClosing else { return }
            withAnimation(.easeOut(duration: Self.slideDuration)) { isShown = true }
        }
    }

    /// Every way out runs the same exit, then tells the door once the card is gone.
    private func dismiss() {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(.easeIn(duration: Self.slideDuration)) { isShown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.slideDuration) { onClose() }
    }

    /// Only text too large for the screen scrolls.
    private var card: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Color.white)
                .padding(.bottom, -Self.cornerRadius)
                .shadow(color: Color.blue900.opacity(0.12), radius: 16, y: 24)
                .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, dismiss)
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { dragOffset = Self.offset(forDrag: $0.translation.height) }
            .onEnded { value in
                if Self.closes(afterDrag: value.translation.height, predicted: value.predictedEndTranslation.height) {
                    dismiss()
                } else {
                    withAnimation(reduceMotion ? nil : .spring()) { dragOffset = 0 }
                }
            }
    }

    /// How far the panel moves for a drag: down with the finger, never up, so it never grows.
    static func offset(forDrag translation: CGFloat) -> CGFloat {
        max(0, translation)
    }

    static func closes(afterDrag translation: CGFloat, predicted: CGFloat) -> Bool {
        translation > closingDrag || predicted > closingDrag * 2
    }

    private var content: some View {
        VStack(spacing: Self.padding) {
            badge
            Image(.webOnlyDateIcon)
                .accessibilityHidden(true)
            Text(message)
                .font(.custom("Usual-Regular", size: 14, relativeTo: .body))
                .lineSpacing(8)
                .foregroundColor(.blue600)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: dismiss) {
                Text("WebOnlyDateGotIt".localized())
                    .sheetButtonLook(fill: .blue25, ink: .blue900)
            }
            .buttonStyle(.plain)
        }
        .padding([.top, .horizontal], Self.padding)
        .padding(.bottom, Self.bottomPadding)
    }

    private var badge: some View {
        Text("WebOnlyDateBadge".localized().uppercased())
            .font(.custom("Usual-Medium", size: 10, relativeTo: .caption2))
            .tracking(1.6)
            .foregroundColor(.warning500)
            .padding(.horizontal, 8)
            .frame(minHeight: 24)
            .background(Capsule().fill(Color.warning100))
    }
}

private extension View {
    /// A full-width 56pt button with 12pt corners.
    func sheetButtonLook(fill: Color, ink: Color) -> some View {
        font(.custom("Usual-Medium", size: 14, relativeTo: .body))
            .foregroundColor(ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 24)
            .background(RoundedRectangle(cornerRadius: 12).fill(fill))
            .contentShape(Rectangle())
    }
}

extension WebOnlyDateMessage {
    static var singleMessage: String { "WebOnlyDateMessage".localized() }

    /// True when this file's date may only be viewed or edited on web.
    static func applies(to displayTime: String?) -> Bool {
        DateUtils.isWebOnlyDate(displayTime)
    }

    /// True when a date door must show this message and keep the date sheet shut. One item alone that saves to
    /// Stela V2 opens the full sheet for a complex date the app can read; in a selection every complex date stops it.
    static func stopsEdit(
        of files: [FileModel],
        sessionArchiveId: Int? = AuthenticationManager.shared.session?.selectedArchive?.archiveID
    ) -> Bool {
        files.contains { stopsEdit(of: $0, displayTime: $0.displayTime, alone: files.count == 1, sessionArchiveId: sessionArchiveId) }
    }

    /// The same for one item whose `displayTime` the door read itself.
    static func stopsEdit(
        of file: FileModel, displayTime: String?, alone: Bool = true,
        sessionArchiveId: Int? = AuthenticationManager.shared.session?.selectedArchive?.archiveID
    ) -> Bool {
        DateUtils.blocksDateEdit(displayTime, fullSheet: alone && file.savesDateToStela(sessionArchiveId: sessionArchiveId))
    }

    /// "2 of the 5 selected items have complex EDTF dates…" for Edit Metadata on several files.
    static func batchMessage(complexCount: Int, of total: Int) -> String {
        let key = complexCount == 1 ? "WebOnlyDateBatchOne" : "WebOnlyDateBatchOther"
        return String(format: key.localized(), complexCount, total)
    }

    /// The single message for one item, the counted one for several.
    static func message(for files: [FileModel]) -> String {
        guard files.count > 1 else { return singleMessage }
        return batchMessage(complexCount: files.filter { applies(to: $0.displayTime) }.count, of: files.count)
    }

    /// The panel for UIKit to present over the whole screen. It closes itself, then calls `onClose`.
    @MainActor
    static func host(for file: FileModel, onClose: (() -> Void)? = nil) -> UIViewController {
        host(message: singleMessage, onClose: onClose)
    }

    /// The same panel with any text, such as the counted one for a selection.
    @MainActor
    static func host(message: String, onClose: (() -> Void)? = nil) -> UIViewController {
        weak var host: UIViewController?
        let view = WebOnlyDateMessage(message: message) {
            host?.dismiss(animated: false) { onClose?() }
        }
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        host = controller
        return controller
    }
}
