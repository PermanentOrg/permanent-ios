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
        let view = UIView()
        let label = UILabel()
        label.text = text
        label.font = TextFontStyle.style34.font
        label.textColor = .middleGray
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(barButtonItemPressed(_:)), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.topAnchor.constraint(equalTo: label.topAnchor),
            button.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])

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
        label.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = TextFontStyle.style12.font
        subtitleLabel.textColor = .dustyGray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(barButtonItemPressed(_:)), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(subtitleLabel)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: -2),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
    private let containerView = UIView()
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

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 32
        containerView.clipsToBounds = true
        containerView.isHidden = true
        containerView.isUserInteractionEnabled = true

        view.addSubview(bgView)
        view.addSubview(containerView)

        widthConstraint = bgView.widthAnchor.constraint(equalToConstant: 32)
        NSLayoutConstraint.activate([
            bgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            bgView.heightAnchor.constraint(equalToConstant: 64),
            widthConstraint,
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 64),
            containerView.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        updateToolbarItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Bring to front to ensure it's above workspace tab bar
        view.superview?.bringSubviewToFront(view)

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            self.widthConstraint.constant = self.containerView.frame.width
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.containerView.isHidden = false
        })
    }

    func animateDismiss(_ completion: (() -> Void)? = nil) {
        containerView.isHidden = true
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

        containerView.isHidden = true
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

        containerView.isHidden = true
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

        // Clear existing subviews
        containerView.subviews.forEach { $0.removeFromSuperview() }

        let leftViews = leftItems.compactMap { $0.barButtonItem?.customView }
        let rightViews = rightItems.compactMap { $0.barButtonItem?.customView }

        // Calculate proper sizes for all views
        leftViews.forEach { view in
            view.sizeToFit()
            view.layoutIfNeeded()
        }
        rightViews.forEach { view in
            view.sizeToFit()
            view.layoutIfNeeded()
        }

        // Add left items
        var previousView: UIView?
        for view in leftViews {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = true
            containerView.addSubview(view)
            
            if let prev = previousView {
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: 32),
                    view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                    view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            }
            previousView = view
        }
        
        // Add right items (from the right side)
        var previousRightView: UIView?
        for view in rightViews.reversed() {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = true
            containerView.addSubview(view)
            
            if let prev = previousRightView {
                NSLayoutConstraint.activate([
                    view.trailingAnchor.constraint(equalTo: prev.leadingAnchor, constant: -32),
                    view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                    view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            }
            previousRightView = view
        }
        
        // Force layout and ensure all interactive elements are accessible
        containerView.layoutIfNeeded()
        containerView.subviews.forEach { subview in
            subview.isUserInteractionEnabled = true
            // Enable interaction on all child views (buttons)
            subview.subviews.forEach { $0.isUserInteractionEnabled = true }
        }
    }
}
