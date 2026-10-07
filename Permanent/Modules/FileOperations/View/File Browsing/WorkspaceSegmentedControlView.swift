//
//  TopSegmentControlView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.04.2023.
//
import UIKit

class WorkspaceSegmentedControlView: UIView {
    var viewModel: SaveDestinationBrowserViewModel?
    let segmentedControl = SlidingTabControl()
    
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
        segmentedControl.titles = [.sharedByMe, .sharedWithMe]
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
    
    @objc func segmentedControlValueChanged(_ sender: SlidingTabControl) {
        viewModel?.workspace = sender.selectedSegmentIndex == 0 ? .sharedByMeFiles : .shareWithMeFiles
    }
}
