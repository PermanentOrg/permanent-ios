//
//  FileContextMenu.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import UIKit

/// The long-press menu for one file, laid out like the Files app: Copy, Move and Share side by side on top,
/// two groups under them, and the destructive item last, on its own.
enum FileContextMenu {
    typealias ItemType = FileMenuViewModel.MenuItem.ItemType

    static let topRow: [ItemType] = [.copy, .move, .shareToPermanent]
    static let groups: [[ItemType]] = [[.download, .shareToAnotherApp], [.rename, .publish], [.delete, .unshare]]

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
        case .shareToPermanent: return .share
        default: return type.title
        }
    }

    static func image(for type: ItemType) -> UIImage? {
        switch type {
        case .copy: return UIImage(systemName: "doc.on.doc")
        case .move: return UIImage(systemName: "folder")
        case .shareToPermanent: return UIImage(systemName: "square.and.arrow.up")
        case .download: return UIImage(systemName: "arrow.down.circle")
        case .shareToAnotherApp: return UIImage(systemName: "paperplane")
        case .rename: return UIImage(systemName: "pencil")
        case .publish: return UIImage(systemName: "globe")
        case .delete: return UIImage(systemName: "trash")
        case .unshare: return UIImage(systemName: "rectangle.portrait.and.arrow.right")
        case .editMetadata: return UIImage(systemName: "info.circle")
        }
    }

    /// Keyed by the item, never by its row: the list can reload while the menu is open.
    static func identifier(for file: FileModel) -> NSString {
        "\(file.recordId)-\(file.folderLinkId)" as NSString
    }

    /// The rows have square corners, so the lifted row gets a rounded outline, 8 pt in from the screen's sides.
    static func preview(for cell: UICollectionViewCell, in collectionView: UICollectionView) -> UITargetedPreview {
        let isGrid = (cell as? FileCollectionViewCell)?.isGridCell ?? false
        let visible = isGrid ? collectionView.bounds : collectionView.bounds.insetBy(dx: 8, dy: 0)
        let parameters = UIPreviewParameters()
        parameters.visiblePath = UIBezierPath(roundedRect: cell.bounds.intersection(cell.convert(visible, from: collectionView)), cornerRadius: 12)
        return UITargetedPreview(view: cell, parameters: parameters)
    }
}
