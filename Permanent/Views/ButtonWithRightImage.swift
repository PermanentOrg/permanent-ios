//
//  ButtonWithRightImage.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 18.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import UIKit

class ButtonWithRightImage: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = self.imageView {
            imageView.frame.origin.x = bounds.width - imageView.frame.width
        }
    }
}
