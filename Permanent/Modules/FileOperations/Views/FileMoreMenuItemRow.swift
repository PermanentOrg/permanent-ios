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
    /// The space around the icon and title. It takes taps too, so the rows meet with no dead gap between them.
    let insets: EdgeInsets
    
    @State private var pressStart: Date?
    
    init(item: FileMenuViewModel.MenuItem, viewModel: FileMenuViewModel, isDestructive: Bool = false, insets: EdgeInsets = EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24), action: @escaping () -> Void) {
        self.item = item
        self.viewModel = viewModel
        self.isDestructive = isDestructive
        self.insets = insets
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
                // VoiceOver needs its own way in: the row's drag gesture has no accessibility action.
                .accessibilityAction { action() }

            let pendingInvitationCount = viewModel.pendingInvitationBadgeCount(for: item.type)
            if pendingInvitationCount > 0 {
                let badgeText = pendingInvitationCount > 9 ? "9+" : "\(pendingInvitationCount)"
                Text(badgeText)
                    .font(
                        .custom("Usual-Medium", size: 8))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.error500)
                    )
            }
            
            Spacer()
        }
        .padding(insets)
        .contentShape(Rectangle())
        // One gesture both times the press and runs the action. With a separate tap gesture,
        // iOS 27 runs a quick tap before the press is timed, and the tap is refused.
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // A new touch starts with no translation. This also clears a touch the system cancelled.
                    if pressStart == nil || value.translation == .zero {
                        pressStart = value.time
                        viewModel.handleMenuItemPressed(item.type)
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
                    let tapDuration = value.time.timeIntervalSince(pressStart ?? value.time)
                    pressStart = nil
                    
                    if viewModel.validateTapGesture(tapDuration: tapDuration, dragDistance: dragDistance, swipeVelocity: swipeVelocity) {
                        action()
                    }
                }
        )
    }
}
