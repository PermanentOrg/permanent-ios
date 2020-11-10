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
        self.setFont(Text.style12.font)
        
        self.setPlaceholderTextColor(.lightGray)
        self.setPlaceholderFont(Text.style12.font)
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
}
