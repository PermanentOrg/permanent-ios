//
//  FileActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import UIKit

protocol SortActionSheetDelegate: AnyObject {
    func didSelectOption(_ option: SortOption)
}

class SortActionSheet: UIView {
    private var sheetView: UIView!
    private var stackView: UIStackView!

    private var onDismiss: ButtonAction!
    private var selectedOption: SortOption!
    
    weak var delegate: SortActionSheetDelegate?


    convenience init(
        frame: CGRect,
        selectedOption: SortOption = .nameAscending,
        onDismiss: @escaping ButtonAction
    ) {
        self.init(frame: frame)
        
        self.onDismiss = onDismiss
        self.selectedOption = selectedOption
        
        initUI()

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    }

    fileprivate func initUI() {
        
        sheetView = UIView()
        sheetView.layer.cornerRadius = 4
        sheetView.backgroundColor = .backgroundPrimary
        
        // Sheet view
        
        addSubview(sheetView)
        sheetView.enableAutoLayout()
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        // Stack view
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        
        sheetView.addSubview(stackView)
        stackView.enableAutoLayout()
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 26),
            stackView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),
            sheetView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20),
            sheetView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 26)
        ])
        
        
        for option in SortOption.allCases where option != self.selectedOption {
            let button = RoundedButton()
            button.bgColor = .primary
            button.tag = option.rawValue
            button.radius = Constants.Design.actionButtonRadius
            button.addTarget(self, action: #selector(didSelectOption(_:)), for: .touchUpInside)
            button.setTitle(option.title, for: [])
            stackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - Actions

    @objc
    func dismiss() {
        onDismiss()
    }
    
    @objc
    func didSelectOption(_ sender: UIButton) {
        print("TAG: ", sender.tag)
        
        guard let option = SortOption(rawValue: sender.tag) else {
            // do nothing ??
            return
        }
        
        delegate?.didSelectOption(option)
        
        dismiss()
    }
}
