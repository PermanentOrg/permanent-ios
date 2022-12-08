//
// Created by Vlad Alexandru Rusu on 08.12.2022.
//

import UIKit

class FloatingActionItem {
    var barButtonItem: UIBarButtonItem? {
        return nil
    }
    var action: (() -> Void)?

    init(action: (() -> Void)?) {
        self.action = action
    }

    @objc func barButtonItemPressed(_ sender: Any) {
        action?()
    }
}

class FloatingActionTextItem: FloatingActionItem {
    var text: String

    override var barButtonItem: UIBarButtonItem? {
        let button = UIBarButtonItem(title: text, style: .plain, target: self, action: #selector(barButtonItemPressed(_:)))
        return button
    }

    init(text: String, action: (() -> Void)?) {
        self.text = text

        super.init(action: action)
    }
}

class FloatingActionTextSubtitleItem: FloatingActionTextItem {
    var subtitle: String

    init(text: String, subtitle: String, action: (() -> Void)?) {
        self.subtitle = subtitle

        super.init(text: text, action: action)
    }

    override var barButtonItem: UIBarButtonItem? {
        let view = UIView()
        let label = UILabel()
        label.text = text
        label.font = Text.style42.font
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = Text.style12.font
        subtitleLabel.textColor = .dustyGray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: -2),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let button = UIBarButtonItem(customView: view)
        button.target = self
        button.action = #selector(barButtonItemPressed(_:))
        button.accessibilityLabel = "\(text), \(subtitle)"
        return button
    }
}

class FloatingActionImageItem: FloatingActionItem {
    var image: UIImage

    override var barButtonItem: UIBarButtonItem? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 32))

        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 8, width: 28, height: 16)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primary
        imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]

        view.addSubview(imageView)

        let button = UIBarButtonItem(customView: view)
        button.target = self
        button.action = #selector(barButtonItemPressed(_:))
        return button
    }

    init(image: UIImage, action: (() -> Void)?) {
        self.image = image

        super.init(action: action)
    }
}

class FloatingActionImageTextItem: FloatingActionTextItem {
    var image: UIImage

    init(text: String, image: UIImage, action: (() -> Void)?) {
        self.image = image

        super.init(text: text, action: action)
    }

    override var barButtonItem: UIBarButtonItem? {
        let view = UIView()

        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 8, width: 28, height: 16)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .primary
        imageView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]

        let label = UILabel(frame: CGRect(x: 28, y: 0, width: 16, height: 32))
        label.text = text
        label.sizeToFit()
        label.frame = CGRect(x: 28, y: 0, width: label.frame.width, height: 32)
        label.font = Text.style34.font
        label.textColor = .black
        label.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]

        view.frame = CGRect(x: 0, y: 0, width: 28 + label.frame.width, height: 32)

        view.addSubview(imageView)
        view.addSubview(label)

        let button = UIBarButtonItem(customView: view)
        button.target = self
        button.action = #selector(barButtonItemPressed(_:))
        return button
    }
}

class FloatingActionIslandViewController: UIViewController {
    let toolbar = UIToolbar()

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
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 16)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 1

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = .white
        toolbar.barTintColor = .white
        toolbar.layer.cornerRadius = 32
        toolbar.clipsToBounds = true

        view.addSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 64),
            toolbar.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        updateToolbarItems()
    }

    func updateToolbarItems() {
        let leftToolbarItems = leftItems.compactMap { $0.barButtonItem }
        let rightToolbarItems = rightItems.compactMap { $0.barButtonItem }

        var items: [UIBarButtonItem] = []

        leftToolbarItems.forEach { (item: UIBarButtonItem) in
            items.append(item)
        }
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        rightToolbarItems.forEach { (item: UIBarButtonItem) in
            items.append(item)
        }
        
        toolbar.setItems(items, animated: true)
    }
}
