//
//  OnBoardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class OnboardingView: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    
    
    let myLabel = UILabel()
    view.addSubview(myLabel)
    //myLabel.frame = CGRect(x: additionalSafeAreaInsets.left, y: view.safeAreaInsets.top, width: 100 , height: 200)
    myLabel.translatesAutoresizingMaskIntoConstraints = false
    setTextWithLineSpacing(label: myLabel, text: "onboarding ", lineSpacing: textStyle14.lineHeight )
    let margineGuide = view.layoutMarginsGuide

    myLabel.backgroundColor = .lightGray
    myLabel.textColor = UIColor.lightBlue
    myLabel.font = textStyle14.font
    myLabel.textAlignment = textStyle14.alignment
     //   myLabel.text = "Onboarding 1\n 2\n 5"
    myLabel.numberOfLines = 0
    NSLayoutConstraint.activate([
        myLabel.topAnchor.constraint(equalTo: margineGuide.topAnchor, constant: 20),
        myLabel.leadingAnchor.constraint(equalTo: margineGuide.leadingAnchor),
        myLabel.heightAnchor.constraint(equalToConstant: 40),
        myLabel.trailingAnchor.constraint(equalTo: margineGuide.trailingAnchor)
        ])
    //myLabel.font =  UIFont(name: "Helvetica-Bold", size: 52)

    
//    view.addSubview(profileImageView)
//    view.addSubview(descriptionTextView)
//
//    setupBottomControls()
//    setupLayout()
  }
  
  func setupBottomControls(){
          
          let yellowView = UIView()
          yellowView.backgroundColor = .yellow
          
          let greenView = UIView()
          greenView.backgroundColor = .green
          
          let blueView = UIView()
          blueView.backgroundColor = .blue
          let bottomControlsStackView = UIStackView(arrangedSubviews: [previousButton, pageControl, nextButton])
          
          bottomControlsStackView.translatesAutoresizingMaskIntoConstraints = false
          bottomControlsStackView.distribution = .fillEqually
          
          view.addSubview(bottomControlsStackView)
          
          NSLayoutConstraint.activate([
              bottomControlsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
              bottomControlsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
              bottomControlsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
              bottomControlsStackView.heightAnchor.constraint(equalToConstant: 50)
          ])
      }
  
   func setupLayout(){
      let topImageContainerView = UIView()
      view.addSubview(topImageContainerView)
      
      topImageContainerView.translatesAutoresizingMaskIntoConstraints = false

      topImageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
      topImageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
      topImageContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      topImageContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
      
      topImageContainerView.addSubview(profileImageView)
      profileImageView.centerXAnchor.constraint(equalTo: topImageContainerView.centerXAnchor).isActive = true
      profileImageView.centerYAnchor.constraint(equalTo: topImageContainerView.centerYAnchor).isActive = true
      profileImageView.heightAnchor.constraint(equalToConstant: 200)
      
      profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
      
      profileImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
      
      profileImageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
      profileImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
      
      descriptionTextView.topAnchor.constraint(equalTo: topImageContainerView.bottomAnchor).isActive = true
      descriptionTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24).isActive = true
      descriptionTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24).isActive = true
      descriptionTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
  }

}

