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
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                        
                        if let completion = completion {
                            completion(true)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if let completion = completion {
                            completion(false)
                        }
                    }
                }
            }
        }
    }
}
