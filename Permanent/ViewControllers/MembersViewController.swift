//  
//  MembersViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class MembersViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addMembersButton: RoundedButton!
    
    lazy var tooltipView = TooltipView(frame: .zero)
    
    var sectionTexts = ["1", "2", "3", "4", "5"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupTableView()
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
}

extension MembersViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: MemberTableViewCell.self, forIndexPath: indexPath)
        cell.updateCell()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = MemberRoleHeader(
            role: "Owner",
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
