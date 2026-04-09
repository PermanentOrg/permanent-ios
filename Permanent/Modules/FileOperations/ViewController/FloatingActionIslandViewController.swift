//
// Created by Vlad Alexandru Rusu on 08.12.2022.
//

import UIKit

class FloatingActionItem {
    var barButtonItem: UIBarButtonItem? {
        return nil
    }
    weak var actionIslandVC: FloatingActionIslandViewController?
    var action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?

    init(action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?) {
        self.action = action
    }

    @objc func barButtonItemPressed(_ sender: Any) {
        action?(actionIslandVC, self)
    }
}

class FloatingActionTextItem: FloatingActionItem {
    var text: String
    
    init(text: String, action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?) {
        self.text = text

        super.init(action: action)
    }

    override var barButtonItem: UIBarButtonItem? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 32))

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 32))
        label.text = text
        label.font = TextFontStyle.style34.font
        label.textColor = .middleGray
        label.lineBreakMode = .byTruncatingTail

        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 32)
        button.addTarget(self, action: #selector(barButtonItemPressed(_:)), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(button)

        let barButton = UIBarButtonItem(customView: view)
        barButton.accessibilityLabel = "\(text)"
        return barButton
    }
}

class FloatingActionTextSubtitleItem: FloatingActionTextItem {
    var subtitle: String

    init(text: String, subtitle: String, action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?) {
        self.subtitle = subtitle

        super.init(text: text, action: action)
    }

    override var barButtonItem: UIBarButtonItem? {
        let view = UIView()

        let label = UILabel()
        label.text = text
        label.font = TextFontStyle.style42.font
        label.textColor = .lightGray
        label.lineBreakMode = .byTruncatingTail
        // Allow the required width=110 constraint below to compress the label
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = TextFontStyle.style12.font
        subtitleLabel.textColor = .dustyGray
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(barButtonItemPressed(_:)), for: .touchUpInside)

        label.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(subtitleLabel)
        view.addSubview(button)

        // A required width constraint is internal to the view, so systemLayoutSizeFitting
        // returns exactly 60pt — UIToolbar allocates 60pt regardless of filename length.
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 60),
            view.heightAnchor.constraint(equalToConstant: 32),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 1),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 15),
            subtitleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 17),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 14),
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let barButton = UIBarButtonItem(customView: view)
        barButton.accessibilityLabel = "\(text), \(subtitle)"
        return barButton
    }
}

class FloatingActionImageItem: FloatingActionItem {
    let image: UIImage?
    let url: URL?
    let contentMode: UIView.ContentMode

    override var barButtonItem: UIBarButtonItem? {
        // On iOS 26, zero-size images serve as spacers — return fixedSpace to split Liquid Glass groups
        if #available(iOS 26, *), let img = image, img.size.width <= 0 {
            return UIBarButtonItem.fixedSpace(8)
        }

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 32))

        let imageView = UIImageView()
        imageView.frame = CGRect(x: 2, y: 4, width: 24, height: 24)
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.tintColor = .primary
        imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        if let image = image {
            imageView.image = image
        } else {
            imageView.sd_setImage(with: url)
        }

        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(barButtonItemPressed(_:)), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 28, height: 32)
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(imageView)
        view.addSubview(button)

        let barButton = UIBarButtonItem(customView: view)
        return barButton
    }

    init(image: UIImage, contentMode: UIView.ContentMode = .scaleAspectFit, action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?) {
        self.image = image
        self.url = nil
        self.contentMode = contentMode

        super.init(action: action)
    }
    
    init(url: URL, contentMode: UIView.ContentMode = .scaleAspectFit, action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?) {
        self.image = nil
        self.url = url
        self.contentMode = contentMode

        super.init(action: action)
    }
}

class FloatingActionImageTextItem: FloatingActionTextItem {
    var image: UIImage

    init(text: String, image: UIImage, action: ((FloatingActionIslandViewController?, FloatingActionItem) -> Void)?) {
        self.image = image

        super.init(text: text, action: action)
    }

    override var barButtonItem: UIBarButtonItem? {
        let view = UIView()

        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 2, y: 4, width: 24, height: 24)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primary
        imageView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]

        let label = UILabel(frame: CGRect(x: 28, y: 0, width: 16, height: 32))
        label.text = text
        label.sizeToFit()
        label.frame = CGRect(x: 28, y: 0, width: label.frame.width, height: 32)
        label.font = TextFontStyle.style34.font
        label.textColor = .black
        label.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]

        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(barButtonItemPressed(_:)), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 28 + label.frame.width, height: 32)
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.frame = CGRect(x: 0, y: 0, width: 28 + label.frame.width, height: 32)

        view.addSubview(imageView)
        view.addSubview(label)
        view.addSubview(button)

        let barButton = UIBarButtonItem(customView: view)
        return barButton
    }
}

class FloatingActionIslandViewController: UIViewController {
    private let toolbar = UIToolbar()
    private let bgView = UIView()

    private var activityIndicator: UIActivityIndicatorView?
    private var doneCheckmarkImageView: UIImageView?

    private var widthConstraint: NSLayoutConstraint!

    var leftItems: [FloatingActionItem] = [] {
        didSet {
            if isViewLoaded {
                updateToolbarItems()
            }
        }
    }

    var rightItems: [FloatingActionItem] = [] {
        didSet {
            if isViewLoaded {
                updateToolbarItems()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.backgroundColor = .white
        bgView.layer.shadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        bgView.layer.shadowOffset = CGSize(width: 0, height: 16)
        bgView.layer.shadowRadius = 32
        bgView.layer.shadowOpacity = 1
        bgView.layer.cornerRadius = 32

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 26, *) {
            // Fully transparent toolbar — no Liquid Glass container, no item glass pills
            let appearance = UIToolbarAppearance()
            appearance.configureWithTransparentBackground()
            toolbar.standardAppearance = appearance
            toolbar.scrollEdgeAppearance = appearance
            // Prevent UIToolbar from reserving bottom safe area space internally
            toolbar.insetsLayoutMarginsFromSafeArea = false

        } else {
            toolbar.backgroundColor = .white
            toolbar.barTintColor = .white
            toolbar.layer.cornerRadius = 32
            toolbar.clipsToBounds = true
        }
        toolbar.isHidden = true

        view.addSubview(bgView)
        view.addSubview(toolbar)

        widthConstraint = bgView.widthAnchor.constraint(equalToConstant: 32)
        let toolbarConstraints: [NSLayoutConstraint]
        if #available(iOS 26, *) {
            // Inset the transparent toolbar 16pt from each pill edge so items
            // don't clip. Also center at 44pt height — iOS 26 reserves bottom
            // safe-area space in UIToolbar which shifts content up in a 64pt frame.
            toolbarConstraints = [
                toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                toolbar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: 44),
            ]
        } else {
            toolbarConstraints = [
                toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                toolbar.topAnchor.constraint(equalTo: view.topAnchor),
                toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: 64),
            ]
        }
        NSLayoutConstraint.activate([
            bgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            bgView.heightAnchor.constraint(equalToConstant: 64),
            widthConstraint,
        ] + toolbarConstraints)

        updateToolbarItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            // On iOS 26 the toolbar is inset from the view edges, so toolbar.frame.width
            // is narrower than the pill should be. Use view.frame.width so the bgView
            // always expands to the full pill width regardless of toolbar insets.
            self.widthConstraint.constant = self.view.frame.width
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.toolbar.isHidden = false
        })
    }

    func animateDismiss(_ completion: (() -> Void)? = nil) {
        toolbar.isHidden = true
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            self.widthConstraint.constant = 64
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }

    func showActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator?.color = .secondary
        activityIndicator?.startAnimating()
        activityIndicator?.frame = CGRect(x: (view.frame.width - 32) / 2, y: 16, width: 32, height: 32)
        activityIndicator?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(activityIndicator!)

        toolbar.isHidden = true
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            self.widthConstraint.constant = 64
            self.view.layoutIfNeeded()
        })
    }

    func hideActivityIndicator() {
        activityIndicator?.removeFromSuperview()
        activityIndicator = nil
    }

    func showDoneCheckmark(_ completion: (() -> Void)? = nil) {
        doneCheckmarkImageView = UIImageView(image: UIImage(named: "checkmarkIcon"))
        doneCheckmarkImageView?.frame = CGRect(x: (view.frame.width - 22) / 2, y: 24, width: 22, height: 16)
        doneCheckmarkImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        doneCheckmarkImageView?.contentMode = .scaleAspectFit
        view.addSubview(doneCheckmarkImageView!)

        toolbar.isHidden = true
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            self.widthConstraint.constant = 64
            self.view.layoutIfNeeded()
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion?()
            }
        })

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func hideDoneCheckmark() {
        doneCheckmarkImageView?.removeFromSuperview()
        doneCheckmarkImageView = nil
    }

    func updateToolbarItems() {
        leftItems.forEach({ $0.actionIslandVC = self })
        rightItems.forEach({ $0.actionIslandVC = self })

        let leftToolbarItems = leftItems.compactMap { $0.barButtonItem }
        let rightToolbarItems = rightItems.compactMap { $0.barButtonItem }

        var items: [UIBarButtonItem] = []

        leftToolbarItems.forEach { items.append($0) }
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        rightToolbarItems.forEach { items.append($0) }

        if #available(iOS 26, *) {
            // Suppress individual Liquid Glass pill backgrounds on all items
            items.forEach { $0.hidesSharedBackground = true }
            // When already visible, cross-dissolve for a smooth count update.
            // animated: true triggers a ~1s Liquid Glass rebuild which causes flicker.
            if toolbar.isHidden {
                toolbar.setItems(items, animated: false)
            } else {
                UIView.transition(with: toolbar, duration: 0.2, options: [.transitionCrossDissolve], animations: {
                    self.toolbar.setItems(items, animated: false)
                })
            }
        } else {
            toolbar.setItems(items, animated: true)
        }
    }
}
