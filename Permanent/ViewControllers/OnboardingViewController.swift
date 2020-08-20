//
//  OnboardingViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class OnboardingViewController: BaseViewController<OnboardingViewModel> {
    
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var topHolderView: UIView!
    
    override var prefersStatusBarHidden: Bool{
    return true
  }
  override func viewDidLoad() {
    
    super.viewDidLoad()
    view.backgroundColor = .darkBlue
    navigationController?.setNavigationBarHidden(true, animated: true)
  
    configure()
  }
  
    //skip button
//navigationController?.setViewControllers([LoginViewController.init(nibName: "LoginViewController", bundle: .main)], animated: true)

}

extension OnboardingViewController: OnboardingViewModelDelegate {
  
  func configure() {
    let scrollView = UIScrollView(frame: holderView.bounds)
    holderView.addSubview(scrollView)
    
    let backButton = UIButton(frame: CGRect(x: topHolderView.frame.size.width - 45, y: 0, width: 40, height: topHolderView.frame.size.height))
    backButton.setTitle("Skip", for: .normal)
    backButton.setTitleColor(.white, for: .normal)
    backButton.addTarget(self, action: #selector(OnboardingViewController.skipPressed(sender:)), for: .touchUpInside)
    backButton.titleLabel?.font = Text.style.font
    topHolderView.addSubview(backButton)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    backButton.centerYAnchor.constraint(equalTo: topHolderView.centerYAnchor).isActive = true
    backButton.trailingAnchor.constraint(equalTo: topHolderView.layoutMarginsGuide.trailingAnchor,constant: 0).isActive = true
    

    
    for x in 0..<3 {
      let pageView = UIView(frame: CGRect(x: CGFloat(x) * (holderView.frame.size.width), y: 0, width: holderView.frame.size.width, height: holderView.frame.size.height))
      scrollView.addSubview(pageView)
      
      let nextButton = RoundedButton()
      nextButton.setTitle("Next", for: .normal)
      nextButton.tag = x
      nextButton.addTarget(self, action: #selector(nextPressed(sender:)), for: .touchUpInside)
      nextButton.setTitle("\(Constants.onboardingBottomButtonText[x])", for: .normal)
      view.willRemoveSubview(nextButton)
      view.addSubview(nextButton)
      
      nextButton.translatesAutoresizingMaskIntoConstraints = false
      nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
      nextButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor,constant: -20).isActive = true
      nextButton.widthAnchor.constraint(equalToConstant: view.frame.size.width - 60).isActive = true
      
      let imageView = UIImageView(frame: CGRect(x: 35, y: 0, width: pageView.frame.size.width-70, height: pageView.frame.size.height - 150))
      let labelTextBold = UILabel(frame: CGRect(x: 0, y: 370, width: pageView.frame.size.width, height: 100))
      let labelTextNormal = UILabel(frame: CGRect(x: 10, y: 470, width: pageView.frame.size.width, height: 100))
      
      imageView.contentMode = .scaleAspectFit
      imageView.image = UIImage(named : "\(Constants.onboardingPageImage[x])")
      pageView.addSubview(imageView)
      
      labelTextBold.attributedText = Text.style.setTextWithLineSpacing(text: Constants.onboardingTextBold[x])
      labelTextBold.numberOfLines = 3
      labelTextBold.textAlignment = Text.style.alignment
      labelTextBold.textColor = .white
      labelTextBold.font = Text.style.font
      pageView.addSubview(labelTextBold)
      
      labelTextNormal.attributedText = Text.style2.setTextWithLineSpacing(text: Constants.onboardingTextNormal[x])
      labelTextNormal.numberOfLines = 3
      labelTextNormal.textAlignment = Text.style2.alignment
      labelTextNormal.textColor = .white
      labelTextNormal.font = Text.style2.font
      labelTextNormal.text = Constants.onboardingTextNormal[x]
      pageView.addSubview(labelTextNormal)
      
    }
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.contentSize = CGSize(width: holderView.frame.size.width*3, height: holderView.frame.size.height)
    scrollView.isPagingEnabled = true
    
  }
  @objc func skipPressed(sender: UIButton!)
  {
    navigationController?.setViewControllers([LoginViewController.init(nibName: "LoginViewController", bundle: .main)], animated: true)
    
  }
  @objc func nextPressed(sender: UIButton!)
  {
    
    guard nextButton.tag < 3 else {
      //dismiss
      return
    }
    
    print("\(sender.tag)")

  }
}

