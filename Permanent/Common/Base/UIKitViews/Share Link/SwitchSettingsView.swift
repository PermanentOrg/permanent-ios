//  
//  SwitchSettingsView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

import UIKit

@IBDesignable
class SwitchSettingsView: UIView {
    fileprivate var textLabel: UILabel!
    fileprivate var switchView: UISwitch!
    
    var delegate: ActionForSwitchSettingsView?
    
    func toggle(isOn: Bool) {
        switchView.setOn(isOn, animated: false)
    }
    
    var isToggled: Bool {
        return switchView.isOn
    }
    
    @IBInspectable
    var text: String? {
        didSet {
            textLabel.text = text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    fileprivate func commonInit() {
        
        textLabel = UILabel()
        textLabel.font = TextFontStyle.style3.font
        textLabel.textColor = .primary
        
        switchView = UISwitch()
        switchView.onTintColor = .mainPurple
        
        self.addSubview(textLabel)
        self.addSubview(switchView)
        
        textLabel.enableAutoLayout()
        switchView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            switchView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            switchView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            switchView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
        
        switchView.addTarget(self, action: #selector(toggleWasPressed(sender:)), for: .touchUpInside)
    }
    
    @objc func toggleWasPressed(sender: UISwitch){
        delegate?.switchToggleWasPressed(sender: sender)
    }
}

protocol ActionForSwitchSettingsView  {
    func switchToggleWasPressed(sender: UISwitch)
}
