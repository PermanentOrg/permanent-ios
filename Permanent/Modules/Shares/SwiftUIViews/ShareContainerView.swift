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
            } else if viewModel.showGrantArchiveAccess {
                ShareGrantArchiveAccessView(viewModel: viewModel)
                    .id("ShareGrantArchiveAccessView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else if viewModel.showInviteAndGrantAccess {
                ShareInviteAndGrantAccessView(viewModel: viewModel)
                    .id("ShareInviteAndGrantAccessView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else if viewModel.showFindArchiveByEmail {
                ShareFindArchiveByEmailView(viewModel: viewModel)
                    .id("ShareFindArchiveByEmailView")
                    .transition(.asymmetric(
                        insertion: viewModel.insertionViewTransition,
                        removal: .opacity
                    ))
            } else if viewModel.showSelectArchiveFromPastShares {
                ShareArchivesFromPastSharesView(viewModel: viewModel)
                    .id("ShareArchivesFromPastSharesView")
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
                    ArchiveAccessNotificationView(message: viewModel.archiveAccessNotificationMessage)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if viewModel.showLinkSettingsNotification {
                    LinkSettingsNotificationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if viewModel.showRevokeLinkNotification {
                    RevokeLinkNotificationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if viewModel.showApproveAllNotification {
                    ApproveAllNotificationView(
                        message: viewModel.approveAllNotificationMessage,
                        isError: viewModel.approveAllNotificationIsError
                    )
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
        .animation(.easeInOut(duration: 0.3), value: viewModel.showGrantArchiveAccess)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showInviteAndGrantAccess)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showFindArchiveByEmail)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSelectArchiveFromPastShares)
        .animation(.easeInOut(duration: 0.3), value: viewModel.navigationDirection)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showCopyNotification)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showArchiveAccessNotification)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showLinkSettingsNotification)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showRevokeLinkNotification)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showApproveAllNotification)
        .onAppear {
            viewModel.refreshData()
        }
    }
}
