//
//  OnboardingChartYourPathViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2024.

import Foundation

class OnboardingChartYourPathViewModel: ObservableObject {
    var containerViewModel: OnboardingContainerViewModel
    
    init(containerViewModel: OnboardingContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func togglePath(path: OnboardingPath) {
        if let index = containerViewModel.selectedPath.firstIndex(of: path) {
            containerViewModel.selectedPath.remove(at: index)
        } else {
            containerViewModel.selectedPath.append(path)
        }
    }
}
