//
//  UISearchBarExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 10/11/2020.
//

import UIKit

extension UISearchBar {
    func setDefaultStyle(placeholder: String) {
        self.placeholder = placeholder
        self.backgroundImage = UIImage()
        self.tintColor = .primary
        self.setBackgroundColor(.galleryGray)
        
        self.setTextColor(.primary)
        self.setFont(TextFontStyle.style12.font)
        
        self.setPlaceholderTextColor(.lightGray)
        self.setPlaceholderFont(TextFontStyle.style12.font)
    }
    
    func setTextColor(_ color: UIColor?) {
        let textFieldInsideUISearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.textColor = color
    }
    
    func setFont(_ font: UIFont) {
        let textFieldInsideUISearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = font
    }
    
    func setPlaceholderTextColor(_ color: UIColor?) {
        let textFieldInsideUISearchBar = self.value(forKey: "searchField") as? UITextField
        let labelInsideUISearchBar = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        
        labelInsideUISearchBar?.textColor = color
    }
    
    func setPlaceholderFont(_ font: UIFont) {
        let textFieldInsideUISearchBar = self.value(forKey: "searchField") as? UITextField
        let labelInsideUISearchBar = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        
        labelInsideUISearchBar?.font = font
    }
    
    func setBackgroundColor(_ color: UIColor) {
        let textFieldInsideUISearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.backgroundColor = color
    }
    /// For changeing height
    func updateHeight(height: CGFloat, radius: CGFloat = 8.0, color: UIColor = UIColor.galleryGray) {
        let image: UIImage? = UIImage.imageWithColor(color: color, size: CGSize(width: 1, height: height))
        setSearchFieldBackgroundImage(image, for: .normal)
        for subview in self.subviews {
            for subSubViews in subview.subviews {
                for child in subSubViews.subviews {
                    if let textField = child as? UISearchTextField {
                        textField.layer.cornerRadius = radius
                        textField.clipsToBounds = true
                    }
                }
                
                if let textField = subSubViews as? UITextField {
                    textField.layer.cornerRadius = radius
                    textField.clipsToBounds = true
                }
            }
        }
    }
}

private extension UIImage {
    static func imageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        guard let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return image
    }
}
