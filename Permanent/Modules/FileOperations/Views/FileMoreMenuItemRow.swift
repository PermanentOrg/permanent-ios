//
//  MenuItemRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2025.
import SwiftUI

struct FileMoreMenuItemRow: View {
    let item: FileMenuViewModel.MenuItem
    let viewModel: FileMenuViewModel
    let action: () -> Void
    let isDestructive: Bool
    
    @State private var tapStartTime: Date = Date()
    
    init(item: FileMenuViewModel.MenuItem, viewModel: FileMenuViewModel, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.item = item
        self.viewModel = viewModel
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 16) {
            viewModel.getIconImage(for: item.type)
                .renderingMode(.template)
                .foregroundColor(isDestructive ? viewModel.isMenuItemPressed(item.type) ? Color.error500.opacity(0.5) : Color.error500 : viewModel.isMenuItemPressed(item.type) ? Color.blue900.opacity(0.5) : Color.blue900)
                .frame(width: 40, height: 40)
            
            Text(viewModel.getTitle(for: item.type))
                .font(
                    .custom("Usual-Regular", size: 14))
                .foregroundColor(isDestructive ? viewModel.isMenuItemPressed(item.type) ? Color.error500.opacity(0.5) : Color.error500 : viewModel.isMenuItemPressed(item.type) ? Color.blue900.opacity(0.5) : Color.blue900)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let tapDuration = Date().timeIntervalSince(tapStartTime)
            let dragDistance: CGFloat = 0
            let swipeVelocity: CGFloat = 0
            
            if viewModel.validateTapGesture(tapDuration: tapDuration, dragDistance: dragDistance, swipeVelocity: swipeVelocity) {
                action()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !viewModel.isMenuItemPressed(item.type) {
                        viewModel.handleMenuItemPressed(item.type)
                        tapStartTime = Date()
                    }
                    
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dragDistance > 10 {
                        viewModel.handleMenuItemReleased()
                    }
                }
                .onEnded { value in
                    viewModel.handleMenuItemReleased()
                    
                    let swipeVelocity = value.predictedEndLocation.y - value.location.y
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    let tapDuration = Date().timeIntervalSince(tapStartTime)
                    if !viewModel.validateTapGesture(tapDuration: tapDuration, dragDistance: dragDistance, swipeVelocity: swipeVelocity) {
                        return
                    }
                }
        )
    }
}
