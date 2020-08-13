//
//  OnBoardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class OnboardingView: UIViewController {
  
  @IBOutlet var holderView: UIView!
  let scrollView = UIScrollView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //    // Do any additional setup after loading the view.
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    view.backgroundColor = .darkBlue
    configure()
  }
  
  private func configure() {
    //set up scrollview
    
    scrollView.frame = holderView.bounds
    scrollView.backgroundColor = .darkBlue
    holderView.addSubview(scrollView)
    
    let titles = ["Welcome","Page2","All Set"]
    for x in 0..<3 {
      let pageView = UIView(frame: CGRect(x: CGFloat(x) * (holderView.frame.size.width), y: 0, width: holderView.frame.size.width, height: holderView.frame.size.height))
      scrollView.addSubview(pageView)
      
      //Title image button
      
      let label = UILabel(frame: CGRect(x: 10, y: 10, width: pageView.frame.size.width-20, height: 120))
      let imageView = UIImageView(frame: CGRect(x: 10, y: 10+120+10, width: pageView.frame.size.width-20, height: pageView.frame.size.height - 60 - 130 - 15))
      let button = UIButton(frame: CGRect(x: 10, y: pageView.frame.size.height-60, width: pageView.frame.size.width-20, height: 50))
      
      label.textAlignment = .center
      label.font = textStyle.font
      label.textColor = .white
      pageView.addSubview(label)
      pageView.addSubview(label)
      label.text = titles[x]
      
      imageView.contentMode = .scaleAspectFit
      imageView.image = UIImage(named : "\(x + 1)")
      pageView.addSubview(imageView)
      
      button.setTitleColor(.white, for: .normal)
      button.backgroundColor = .tangerine
      button.setTitle("Next", for: .normal)
      if x == 2 {
        button.setTitle("Get Started", for: .normal)
      }
      button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
      button.tag = x+1
      pageView.addSubview(button)
    }
    
    scrollView.contentSize = CGSize(width: holderView.frame.size.width*3, height: holderView.frame.size.height)
    
    scrollView.isPagingEnabled = true
  }
  
  @objc func didTapButton(_ button: UIButton){
    guard button.tag < 3 else {
      //dismiss
      //Core.shared.setIsNotNewUser()
      dismiss(animated: true, completion: nil)
      return
    }
    // scroll to next page
    scrollView.setContentOffset(CGPoint(x: holderView.frame.size.width * CGFloat(button.tag), y: 0), animated: true)
  }
  
  
}
