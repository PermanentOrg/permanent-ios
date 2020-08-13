//
//  OnboardingModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit



let profileImageView: UIImageView = {
    let imageView = UIImageView()
    let profile = UIImage(named: "onboard")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    
    imageView.image = profile
    
    return imageView
}()

let descriptionTextView: UITextView = {
   let textView = UITextView()
    
    let attributedText = NSMutableAttributedString(string: "Join us today in our fun lunch!", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
    
    attributedText.append(NSAttributedString(string: "\n\n\nAre you ready for loads and loads for fun? Don't wait any longer! We hope to see you in our event today.", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.foregroundColor: UIColor.gray]))
    
    textView.attributedText = attributedText
    
    textView.textAlignment = .center
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    
    return textView
}()
 let previousButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("PREV", for: .normal)
       button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
       button.setTitleColor(.gray, for: .normal)
       button.translatesAutoresizingMaskIntoConstraints = false
       return button
   }()
   
 let nextButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("NEXT", for: .normal)
       button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
       button.setTitleColor(.mainPink, for: .normal)
       button.translatesAutoresizingMaskIntoConstraints = false
       return button
   }()

 let pageControl: UIPageControl = {
    let pc = UIPageControl()
    pc.currentPage = 0
    pc.numberOfPages = 4
    pc.currentPageIndicatorTintColor = .mainPink
    pc.pageIndicatorTintColor = .gray
    
    return pc
}()
