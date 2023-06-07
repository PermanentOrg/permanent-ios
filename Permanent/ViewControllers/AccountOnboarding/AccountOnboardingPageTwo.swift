//
//  AccountOnboardingPageTwo.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 04.05.2022.
//

import UIKit

class AccountOnboardingPageTwo: BaseViewController<AccountOnboardingViewModel> {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    @IBOutlet weak var personContainerView: UIView!
    @IBOutlet weak var personImageView: UIImageView!
    @IBOutlet weak var personTitleLabel: UILabel!
    @IBOutlet weak var personDetailsLabel: UILabel!
    
    @IBOutlet weak var groupContainerView: UIView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupTitleLabel: UILabel!
    @IBOutlet weak var groupDetailsLabel: UILabel!
    
    @IBOutlet weak var organizationContainerView: UIView!
    @IBOutlet weak var organizationImageView: UIImageView!
    @IBOutlet weak var organizationTitleLabel: UILabel!
    @IBOutlet weak var organizationDetailsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.font = TextFontStyle.style.font
        detailsLabel.font = TextFontStyle.style5.font
        
        personTitleLabel.font = TextFontStyle.style17.font
        personDetailsLabel.font = TextFontStyle.style5.font
        
        groupTitleLabel.font = TextFontStyle.style17.font
        groupDetailsLabel.font = TextFontStyle.style5.font
        
        organizationTitleLabel.font = TextFontStyle.style17.font
        organizationDetailsLabel.font = TextFontStyle.style5.font
        
        setupContainerView(personContainerView)
        personImageView.tintColor = .primary
        
        setupContainerView(groupContainerView)
        groupContainerView.tintColor = .primary
        
        setupContainerView(organizationContainerView)
        organizationContainerView.tintColor = .primary
        
        updateSelectedType()
    }
    
    func updateSelectedType() {
        switch viewModel?.archiveType {
        case .person:
            setSelected(true, containerView: personContainerView, titleLabel: personTitleLabel, detailsLabel: personDetailsLabel, imageView: personImageView)
            setSelected(false, containerView: groupContainerView, titleLabel: groupTitleLabel, detailsLabel: groupDetailsLabel, imageView: groupImageView)
            setSelected(false, containerView: organizationContainerView, titleLabel: organizationTitleLabel, detailsLabel: organizationDetailsLabel, imageView: organizationImageView)
            
        case .family:
            setSelected(false, containerView: personContainerView, titleLabel: personTitleLabel, detailsLabel: personDetailsLabel, imageView: personImageView)
            setSelected(true, containerView: groupContainerView, titleLabel: groupTitleLabel, detailsLabel: groupDetailsLabel, imageView: groupImageView)
            setSelected(false, containerView: organizationContainerView, titleLabel: organizationTitleLabel, detailsLabel: organizationDetailsLabel, imageView: organizationImageView)
            
        case .organization:
            setSelected(false, containerView: personContainerView, titleLabel: personTitleLabel, detailsLabel: personDetailsLabel, imageView: personImageView)
            setSelected(false, containerView: groupContainerView, titleLabel: groupTitleLabel, detailsLabel: groupDetailsLabel, imageView: groupImageView)
            setSelected(true, containerView: organizationContainerView, titleLabel: organizationTitleLabel, detailsLabel: organizationDetailsLabel, imageView: organizationImageView)
            
        default: break
        }
    }
    
    func setupContainerView(_ containerView: UIView) {
        containerView.layer.borderColor = UIColor.primary.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 5
    }
    
    func setSelected(_ selected: Bool, containerView: UIView, titleLabel: UILabel, detailsLabel: UILabel, imageView: UIImageView) {
        containerView.backgroundColor = selected ? UIColor.primary : UIColor.white
        titleLabel.textColor = selected ? .white : .primary
        detailsLabel.textColor = selected ? .white : .black
        imageView.tintColor = selected ? .white : .primary
    }
    
    @IBAction func personButtonPressed(_ sender: Any) {
        viewModel?.archiveType = .person
        updateSelectedType()
    }
    
    @IBAction func groupButtonPressed(_ sender: Any) {
        viewModel?.archiveType = .family
        updateSelectedType()
    }
    
    @IBAction func organizationButtonPressed(_ sender: Any) {
        viewModel?.archiveType = .organization
        updateSelectedType()
    }
}
