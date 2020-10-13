//
//  MainViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import Foundation
import UIKit

class MyFilesViewModel: NSObject, ViewModelInterface {
    weak var delegate: MyFilesViewModelDelegate?
}

protocol MyFilesViewModelDelegate: ViewModelDelegateInterface {}

extension MyFilesViewModel: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileTableViewCell")!
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
