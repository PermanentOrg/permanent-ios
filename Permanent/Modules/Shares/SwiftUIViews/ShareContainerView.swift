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
            if viewModel.showGeneralAccess {
                GeneralAccessView(viewModel: viewModel)
                    .id("GeneralAccessView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else if viewModel.showRoleSelection {
                RoleSelectionView(viewModel: viewModel)
                    .id("RoleSelectionView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else if viewModel.showArchiveAccessManagement {
                ArchiveAccessManagementView(viewModel: viewModel)
                    .id("ArchiveAccessManagementView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else if viewModel.showLinkSettings {
                LinkSettingsView(viewModel: viewModel)
                    .id("LinkSettingsView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else {
                ShareItemView(viewModel: viewModel)
                    .id("ShareItemView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            }
            
            VStack {
                Spacer()
                
                if viewModel.showCopyNotification {
                    LinkCopyNotificationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if viewModel.showArchiveAccessNotification {
                    ArchiveAccessNotificationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showLinkSettings)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showGeneralAccess)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showRoleSelection)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showArchiveAccessManagement)
        .animation(.easeInOut(duration: 0.3), value: viewModel.navigationDirection)
    }
}
