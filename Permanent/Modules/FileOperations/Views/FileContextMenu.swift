//
//  FileContextMenu.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import UIKit

/// The long-press menu for one file, laid out like the Files app: Copy, Move and Share side by side on top,
/// the file's other actions under them, and the destructive item last, on its own.
enum FileContextMenu {
    typealias ItemType = FileMenuViewModel.MenuItem.ItemType

    /// Share is the phone's share sheet; sharing inside Permanent is the first row under it.
    static let topRow: [ItemType] = [.copy, .move, .shareToAnotherApp]
    static let groups: [[ItemType]] = [[.shareToPermanent, .publish, .fileInformation, .rename], [.delete, .unshare]]

    /// Whether the menu would show anything; Save, a viewer's only action in a shared folder, stays in the … sheet.
    static func hasActions(for types: [ItemType]) -> Bool {
        types.contains { topRow.contains($0) || groups.joined().contains($0) }
    }

    /// `types` decides which actions appear; the layout above decides where.
    static func make(for types: [ItemType], perform: @escaping (ItemType) -> Void) -> UIMenu {
        func actions(_ order: [ItemType]) -> [UIAction] {
            order.filter(types.contains).map { type in
                let action = UIAction(title: title(for: type), image: image(for: type), attributes: type.isDestructive ? .destructive : []) { _ in
                    perform(type)
                }
                action.accessibilityIdentifier = "fileContextMenu.\(type.rawValue)"
                return action
            }
        }
        let row = UIMenu(options: .displayInline, preferredElementSize: .medium, children: actions(topRow))
        let rest = groups.map { UIMenu(options: .displayInline, children: actions($0)) }
        return UIMenu(children: ([row] + rest).filter { !$0.children.isEmpty })
    }

    static func title(for type: ItemType) -> String {
        switch type {
        case .copy: return .copy
        case .move: return .move
        case .shareToAnotherApp: return .share
        default: return type.title
        }
    }

    /// The … sheet's icons, so both menus look alike. The sheet has no icon for Share, so it takes a system one.
    static func image(for type: ItemType) -> UIImage? {
        let name: String
        switch type {
        case .shareToAnotherApp: return UIImage(systemName: "arrow.up.forward.app")
        case .copy: name = "copyV1"
        case .move: name = "moveV1"
        case .shareToPermanent: name = "ShareAndManageV1"
        case .publish: name = "publishOnWebV1"
        case .fileInformation, .editMetadata: name = "fileInfoV1"
        case .rename: name = "renameV1"
        case .download: name = "downloadV1"
        case .delete: name = "deleteV1"
        case .unshare: name = "publishRevokeLink"
        }
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
    }

    /// Keyed by the item, never by its row: the list can reload while the menu is open.
    static func identifier(for file: FileModel) -> NSString {
        "\(file.recordId)-\(file.folderLinkId)" as NSString
    }

    static func preview(for cell: UICollectionViewCell, in collectionView: UICollectionView) -> UITargetedPreview {
        let parameters = UIPreviewParameters()
        parameters.visiblePath = liftedPath(for: cell, in: collectionView)
        return UITargetedPreview(view: cell, parameters: parameters)
    }

    /// The rows have square corners, so a lifted row gets a rounded outline, 8 pt in from the screen's sides.
    /// A drag keeps the same outline, so the row does not change shape when the menu turns into a drag.
    static func liftedPath(for cell: UICollectionViewCell, in collectionView: UICollectionView) -> UIBezierPath {
        let isGrid = (cell as? FileCollectionViewCell)?.isGridCell ?? false
        let visible = isGrid ? collectionView.bounds : collectionView.bounds.insetBy(dx: 8, dy: 0)
        return UIBezierPath(roundedRect: cell.bounds.intersection(cell.convert(visible, from: collectionView)), cornerRadius: 12)
    }
}
