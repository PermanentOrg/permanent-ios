//
//  UIImageViewExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15/10/2020.
//

import UIKit.UIImageView

extension UIImageView {
    func load(urlString: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: urlString) else {
            return
        }

        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                    completion?(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
}
