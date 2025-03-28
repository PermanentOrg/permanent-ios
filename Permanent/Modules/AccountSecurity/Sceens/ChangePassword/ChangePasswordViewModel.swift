//
//  ChangePasswordViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.03.2025.
import SwiftUI

class ChangePasswordViewModel: ObservableObject {
    @Published var showBottomBanner: Bool = false
    @Published var bottomBannerMessage: BannerBottomMessage = .none
    @Published var showError: Bool = false
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    func displayBanner() {
        if showBottomBanner {
            withAnimation {
                showBottomBanner = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    self.showBottomBanner = true
                }
            }
        } else {
            withAnimation {
                showBottomBanner = true
            }
        }
    }
    
    func displayBannerWithAutoClose() {
        displayBanner()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation {
                self?.showBottomBanner = false
            }
        }
    }
}

