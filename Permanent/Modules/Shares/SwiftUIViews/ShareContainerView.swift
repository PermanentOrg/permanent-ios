//
//  ShareContainerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.09.2025.
//

import SwiftUI

struct ShareContainerView: View {
    @StateObject private var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(fileModel: FileModel) {
        self._viewModel = StateObject(wrappedValue: ShareItemViewModel(fileModel: fileModel))
    }
    
    var body: some View {
        ZStack {
            if viewModel.showLinkSettings {
                LinkSettingsView(viewModel: viewModel)
                    .transition(.move(edge: .trailing))
            } else {
                ShareItemView(viewModel: viewModel)
                    .transition(.move(edge: .leading))
            }
            
            // Copy notification overlay
            VStack {
                Spacer()
                
                if viewModel.showCopyNotification {
                    LinkCopyNotificationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showLinkSettings)
    }
}
