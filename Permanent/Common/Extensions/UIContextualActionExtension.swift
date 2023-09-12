//
//  UIContextualActionExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 06/11/2020.
//

import UIKit

extension UIContextualAction {
    public static func make(
        withImage image: UIImage,
        backgroundColor: UIColor,
        handler: @escaping UIContextualAction.Handler) -> UIContextualAction
    {
        let action = UIContextualAction(style: .normal, title: nil, handler: handler)
        action.image = image
        action.backgroundColor = backgroundColor
        return action
    }
}
