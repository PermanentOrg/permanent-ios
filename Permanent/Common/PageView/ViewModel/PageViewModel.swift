//
//  PageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24/08/2020.
//

import Foundation

class PageViewModel: PageViewModelInterface {
    weak var delegate: PageViewModelDelegate?
    var currentPage = 0 {
        didSet {
            onCurrentPageChange?(currentPage,delegate?.numberOfViewControllers() ?? 0)
        }
    }
    var onCurrentPageChange: ((Int, Int) -> Void)?
    
    func viewDidLoad() {
        delegate?.createViewControllers()
        delegate?.setViewController(of: 0)
    }
    
    func moveToNextPage () -> Bool {
        if currentPage < (delegate?.numberOfViewControllers() ?? 0) - 1 {
            currentPage += 1
            delegate?.setViewController(of: currentPage)
            return true
        } else {
            return false
        }
    }
    
    func nextPageIndex(after index: Int) -> Int? {
        if index < (delegate?.numberOfViewControllers() ?? 0) - 1 {
            return index + 1
        } else {
            return nil
        }
    }
    
    func beforePageIndex(before index: Int) -> Int? {
        if index > 0 {
            return index - 1
        } else {
            return nil
        }
    }
}

protocol PageViewModelDelegate: PageViewModelDelegateInterface { }
