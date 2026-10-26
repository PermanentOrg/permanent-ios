//
//  UINavigationControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import UIKit

extension UINavigationController {
    func display(viewController: UIViewController, modally: Bool = false) {
        if modally {
            viewController.modalPresentationStyle = .popover
            self.present(viewController, animated: true)
        } else {
            self.pushViewController(viewController, animated: true)
        }
    }

    func display(_ id: ViewControllerId, from storyboard: StoryboardName, modally: Bool = false) {
        let viewController = UIViewController.create(withIdentifier: id, from: storyboard)
        self.display(viewController: viewController, modally: modally)
    }
}

extension UINavigationBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 55)
    }

    /// A dark-blue bar with a white title for every bar made after this call, which a SwiftUI screen's bar reads.
    static func applyDarkBlueLook() {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: TextFontStyle.style51.font
        ]
        appearance().backgroundColor = .darkBlue
        appearance().titleTextAttributes = titleAttributes
        appearance().isTranslucent = false

        let look = UINavigationBarAppearance()
        look.configureWithOpaqueBackground()
        look.titleTextAttributes = titleAttributes
        look.backgroundColor = UIColor.darkBlue
        appearance().standardAppearance = look
        appearance().compactAppearance = look
        appearance().scrollEdgeAppearance = look
    }

    /// On iOS 26 the look above bleeds into every SwiftUI stack, so a screen clears it when it goes.
    static func clearDarkBlueLook() {
        guard #available(iOS 26.0, *) else { return }
        let transparent = UINavigationBarAppearance()
        transparent.configureWithTransparentBackground()
        appearance().standardAppearance = transparent
        appearance().compactAppearance = transparent
        appearance().scrollEdgeAppearance = transparent
        appearance().backgroundColor = nil
        appearance().isTranslucent = true
    }
}
