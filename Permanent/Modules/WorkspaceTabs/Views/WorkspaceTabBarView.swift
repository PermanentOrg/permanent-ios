//
//  WorkspaceTabBarView.swift
//  Permanent
//
//  Created by GitHub Copilot on 17.12.2025.
//

import SwiftUI

@available(iOS 26, *)
struct WorkspaceTabBarView: View {
    @ObservedObject var viewModel: WorkspaceTabViewModel
    
    let onWorkspaceSelected: (WorkspaceType) -> Void
    let onPlusButtonTapped: () -> Void
    let onChecklistButtonTapped: () -> Void
    
    private let tabBarHeight: CGFloat = 80
    
    var body: some View {
        HStack(spacing: 12) {
            // Glass pill with workspace tabs only
            GlassEffectContainer {
                HStack(spacing: 8) {
                    ForEach(WorkspaceType.allCases, id: \.self) { workspace in
                        WorkspaceTabButton(
                            workspace: workspace,
                            isSelected: viewModel.selectedWorkspace == workspace,
                            action: {
                                // Update view model FIRST, synchronously
                                viewModel.selectedWorkspace = workspace
                                // Then navigate
                                onWorkspaceSelected(workspace)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassEffect(in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
            
            // Separate floating action buttons - stacked vertically
            VStack(spacing: 12) {
                if viewModel.showPlusButton {
                    ActionButton(iconName: "plus", action: onPlusButtonTapped)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if viewModel.showChecklistButton {
                    ActionButton(iconName: "checklist", action: onChecklistButtonTapped)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: tabBarHeight)
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 26, *)
struct WorkspaceTabButton: View {
    let workspace: WorkspaceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: workspace.iconName)
                    .font(.system(size: 22, weight: .medium))
                
                Text(workspace.title)
                    .font(.custom("Usual-Regular", size: 12))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .fixedSize()
            }
            .foregroundColor(isSelected ? Color(red: 0.07, green: 0.11, blue: 0.29) : Color(red: 0.47, green: 0.49, blue: 0.57))
            .frame(minWidth: 70)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 26, *)
struct ActionButton: View {
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - iOS 16-25 Fallback (not used, kept for reference)
// On older iOS versions, the app will continue using the existing FABView
// No changes are made to the legacy behavior

#if DEBUG
@available(iOS 26, *)
struct WorkspaceTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = WorkspaceTabViewModel()
        viewModel.showPlusButton = true
        viewModel.showChecklistButton = true
        
        return WorkspaceTabBarView(
            viewModel: viewModel,
            onWorkspaceSelected: { _ in },
            onPlusButtonTapped: {},
            onChecklistButtonTapped: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif
