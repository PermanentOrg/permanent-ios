//
//  OnboardingCreateFirstArchiveViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2024.

import Foundation

class OnboardingCreateFirstArchiveViewModel: ObservableObject {
    var containerViewModel: OnboardingContainerViewModel
    
    init(containerViewModel: OnboardingContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
}
