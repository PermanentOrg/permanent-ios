//
//  ViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet var labelLogin: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .darkBlue
    labelLogin.textColor = .white
  }
  
  //MARK: - OnboardingView display
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    if Core.shared.isNewUser(){
      //show onboarding
      let vc = storyboard?.instantiateViewController(withIdentifier: "onboarding") as! OnboardingView
      vc.modalPresentationStyle = .fullScreen
      present(vc,animated: true)
    }
    
  }
}

class Core {
  static let shared = Core()
  
  func isNewUser() -> Bool {
    return !UserDefaults.standard.bool(forKey: "isNewUser")
  }
  
  func setIsNotNewUser() {
    UserDefaults.standard.set(true, forKey: "isNewUser")
    
  }
}
