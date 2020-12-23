//  
//  MembersViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class MembersViewController: BaseViewController<MembersViewModel> {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addMembersButton: RoundedButton!
    
    lazy var tooltipView = TooltipView(frame: .zero)
    
    var sectionTexts = ["1", "2", "3", "4", "5", "6"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = MembersViewModel()
        
        configureUI()
        setupTableView()
        
        getMembers()
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .members
        view.backgroundColor = .backgroundPrimary
        addMembersButton.configureActionButtonUI(title: .addMembers)
    }
    
    fileprivate func setupTableView() {
        tableView.register(cellClass: MemberTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 40
    }
    
    @IBAction func addMembersAction(_ sender: UIButton) {
        self.showToast(message: "Add members")
    }
    
    fileprivate func showTooltip(anchorPoint: CGPoint, text: String) {
    
        // Check if tooltip view is already presented on screen.
        // If it is visible, we remove it, before presenting it to the new location.
        if tooltipView.isDescendant(of: view) {
            tooltipView.removeFromSuperview()
        }
        
        tooltipView.text = text
        view.addSubview(tooltipView)
        tooltipView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            tooltipView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: anchorPoint.x),
            tooltipView.topAnchor.constraint(equalTo: view.topAnchor, constant: anchorPoint.y),
            tooltipView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    fileprivate func getMembers() {
        viewModel?.getMembers(then: { status in
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
    }
}

extension MembersViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return AccessRole.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let accessRole = AccessRole(rawValue: section) else { return 0 }
        
        return viewModel?.numberOfItemsForRole(accessRole) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let accessRole = AccessRole(rawValue: indexPath.section) else {
            fatalError()
        }
        
        let cell = tableView.dequeue(cellClass: MemberTableViewCell.self, forIndexPath: indexPath)
        cell.member = viewModel?.itemAtRow(indexPath.row, withRole: accessRole)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let accessRole = AccessRole(rawValue: section) else {
            fatalError()
        }
        
        let headerView = MemberRoleHeader(
            role: accessRole.groupName.pluralized(),
            tooltipText: "Lorem Ipsum is ansjda sdjan dajsnd jasdnasj dasjdnasj dnasjd njasnds ajdasnaj  \(sectionTexts[section])",
            action: { point, text in
                self.showTooltip(anchorPoint: point, text: text)
            })
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard tooltipView.isDescendant(of: view) else { return }
        tooltipView.removeFromSuperview()
    }
}
