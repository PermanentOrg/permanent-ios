//
//  TopSegmentControlView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.04.2023.
//
import UIKit

class WorkspaceSegmentedControlView: UIView {
    var viewModel: SaveDestinationBrowserViewModel?
    let segmentedControl = UISegmentedControl(items: ["", ""])
    
    init() {
        super.init(frame: .zero)
        
        self.initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 60)
    }
    
    func initUI() {
        backgroundColor = .backgroundPrimary
        addSubview(segmentedControl)
        configureSegmentedControl()
        setupConstraints()
    }
    
    func configureSegmentedControl() {
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: Text.style8.font], for: .normal)
        segmentedControl.setTitle(.sharedByMe, forSegmentAt: 0)
        segmentedControl.setTitle(.sharedWithMe, forSegmentAt: 1)
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .primary
        }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
    func setupConstraints() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        viewModel?.workspace = sender.selectedSegmentIndex == 0 ? .sharedByMeFiles : .shareWithMeFiles
    }
}
