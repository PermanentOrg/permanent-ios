//  
//  ActionDialogStyle.swift
//  Permanent
//
//  Created by Adrian Creteanu on 05/11/2020.
//

import Foundation

enum ActionDialogStyle {
    
    /// Simple dialog with title and action buttons.
    case simple
    
    /// Simple dialog with title, description and action buttons.
    case simpleWithDescription
    
    /// Dialog with title, an input field and action buttons.
    case singleField
    
    /// Dialog with title, multiple input field and action buttons.
    case multipleFields
    
    /// Dialog with title, description and action buttons.
    case dropdownWithDescription
    
    /// Dialog with title, an input field and a dropdown (UIPickerView).
    case inputWithDropdown
    
    /// New UI design for simple dialog with title.
    case updatedSimpleWithDescription
}
