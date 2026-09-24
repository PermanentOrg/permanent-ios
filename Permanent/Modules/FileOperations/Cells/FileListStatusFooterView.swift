//
//  FileListStatusFooterView.swift
//  Permanent
//

import UIKit

/// The end of a folder list: its folder and file counts, or the next page's error with a retry button.
class FileListStatusFooterView: UICollectionReusableView {
    static let identifier = "FileListStatusFooterView"

    enum Content: Equatable {
        case hidden
        case counts(folders: Int, files: Int)
        case failed
    }

    var retryAction: (() -> Void)?

    private let stackView = UIStackView()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    private static let padding: CGFloat = 24

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: FileListStatusFooterView.padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        messageLabel.font = FileListStatusFooterView.messageFont(compatibleWith: nil)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        stackView.addArrangedSubview(messageLabel)

        let symbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        retryButton.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: symbolConfiguration), for: .normal)
        retryButton.tintColor = .darkBlue
        retryButton.accessibilityLabel = "TryAgain".localized()
        retryButton.addTarget(self, action: #selector(retryPressed), for: .touchUpInside)
        NSLayoutConstraint.activate([
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        stackView.addArrangedSubview(retryButton)

        configure(.hidden)
    }

    func configure(_ content: Content) {
        switch content {
        case .hidden:
            stackView.isHidden = true

        case .counts(let folders, let files):
            stackView.isHidden = false
            retryButton.isHidden = true
            messageLabel.textColor = UIColor(.blue400)
            messageLabel.text = FileListStatusFooterView.countsText(folders: folders, files: files)

        case .failed:
            stackView.isHidden = false
            retryButton.isHidden = false
            messageLabel.textColor = UIColor(.error500)
            messageLabel.text = "CouldntLoadMoreItems".localized()
        }
    }

    static func countsText(folders: Int, files: Int) -> String {
        let folderText = String(format: (folders == 1 ? "FolderCountOne" : "FolderCountOther").localized(), folders)
        let fileText = String(format: (files == 1 ? "FileCountOne" : "FileCountOther").localized(), files)
        return "\(folderText), \(fileText)"
    }

    private static func messageFont(compatibleWith traits: UITraitCollection?) -> UIFont {
        let baseFont = UIFont(name: "Usual-Regular", size: 14) ?? .systemFont(ofSize: 14)
        return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: baseFont, compatibleWith: traits)
    }

    private static let sizingView = FileListStatusFooterView()

    /// Self-sized with the list's current text size, so the message and button keep their room when it grows.
    static func height(for content: Content, width: CGFloat, traits: UITraitCollection) -> CGFloat {
        guard content != .hidden else { return 0 }
        sizingView.configure(content)
        sizingView.messageLabel.font = messageFont(compatibleWith: traits)
        let symbolFont = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
        sizingView.retryButton.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: UIImage.SymbolConfiguration(font: symbolFont)), for: .normal)
        let fitting = sizingView.stackView.systemLayoutSizeFitting(
            CGSize(width: width - 32, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return ceil(fitting.height) + padding * 2
    }

    @objc private func retryPressed() {
        retryAction?()
    }
}
