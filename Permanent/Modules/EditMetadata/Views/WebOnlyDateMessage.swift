//
//  WebOnlyDateMessage.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2026.
//

import SwiftUI
import UIKit

/// The "Coming soon to mobile" sheet every date door shows for a complex date, in place of the date sheet.
struct WebOnlyDateMessage: View {
    let message: String
    let onClose: () -> Void

    static let cornerRadius: CGFloat = 38
    private static let padding: CGFloat = 32
    /// The sheet already keeps the home indicator's area clear, which stands in for the bottom padding.
    private static var bottomPadding: CGFloat {
        let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first { $0.isKeyWindow }
        return (window?.safeAreaInsets.bottom ?? 0) > 0 ? 0 : padding
    }

    /// The sheet hugs its content, so nothing scrolls; only text too large for the screen scrolls.
    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .background(Color.white.ignoresSafeArea())
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
            Button(action: onClose) {
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
        DateUtils.isComplexDate(displayTime)
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

    /// The sheet's height for its content at the screen's width, for a detent that hugs it.
    /// Measured once per message, width and text size, then kept, since a view body asks on every redraw.
    @MainActor
    static func fittingHeight(message: String, width: CGFloat = UIScreen.main.bounds.width) -> CGFloat {
        let key = "\(message)|\(width)|\(UIApplication.shared.preferredContentSizeCategory.rawValue)"
        if let height = measuredHeights[key] { return height }
        let sample = WebOnlyDateMessage(message: message, onClose: {})
        let height = UIHostingController(rootView: sample).sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        measuredHeights[key] = height
        return height
    }

    @MainActor private static var measuredHeights: [String: CGFloat] = [:]

    /// The sheet for UIKit to present. It closes itself, then calls `onClose`.
    @MainActor
    static func host(for file: FileModel, onClose: (() -> Void)? = nil) -> UIViewController {
        weak var host: UIViewController?
        let view = WebOnlyDateMessage(message: singleMessage) {
            host?.dismiss(animated: true) { onClose?() }
        }
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .white
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            let height = fittingHeight(message: singleMessage)
            sheet.detents = [.custom { _ in height }]
            sheet.preferredCornerRadius = cornerRadius
        }
        host = controller
        return controller
    }
}
