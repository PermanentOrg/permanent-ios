//
//  BasePageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit
class BasePageViewController<T: PageViewModelInterface>: UIPageViewController {
    
    var viewModel: T?
    var currentViewControllers = [UIViewController]()
    var pageControl = UIPageControl.appearance()
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel?.viewWillDisappear()
    }
}
