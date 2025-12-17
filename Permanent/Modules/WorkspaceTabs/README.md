# WorkspaceTabs Module

## Overview
This module provides the iOS 26+ Liquid Glass workspace navigation tab bar for the Permanent app. It enables users to quickly switch between Private, Shared, and Public workspaces with a modern, translucent bottom tab interface.

## Structure

```
WorkspaceTabs/
├── ViewModel/
│   └── WorkspaceTabViewModel.swift    # State management and business logic
├── Views/
│   └── WorkspaceTabBarView.swift      # SwiftUI UI components
└── README.md                          # This file
```

## Components

### WorkspaceTabViewModel
**Type:** `ObservableObject`

Manages the state and business logic for workspace tab navigation:
- **Properties:**
  - `selectedWorkspace`: Current workspace (Private/Shared/Public)
  - `showPlusButton`: Visibility based on create+upload permissions
  - `showChecklistButton`: Member checklist visibility
  
- **Features:**
  - Listens to `ArchivesViewModel.didChangeArchiveNotification`
  - Automatically updates button visibility based on archive permissions
  - Uses Combine for reactive updates

### WorkspaceTabBarView
**Type:** `SwiftUI View` (iOS 26+)

The main UI component featuring:
- **Liquid Glass Effect:** Uses `GlassEffectContainer` and `.glassEffect()` modifier
- **Three Workspace Tabs:** Private (lock icon), Shared (people icon), Public (globe icon)
- **Action Buttons:** Plus button for uploads, checklist button for member setup
- **Animations:** Smooth 0.25s easeInOut transitions
- **Responsive Design:** Adapts to content and permissions

## Usage

### Integration in MainViewController

```swift
// Setup (iOS 26+)
if #available(iOS 26, *) {
    setupWorkspaceTabBar()
} else {
    // Fall back to legacy FABView
    fabView.delegate = self
}

// Workspace switching
private func handleWorkspaceSelection(_ workspace: WorkspaceType) {
    switch workspace {
    case .private:
        // Navigate to MyFilesViewModel
    case .shared:
        // Navigate to SharesViewController
    case .public:
        // Navigate to PublicFilesViewModel
    }
}
```

## iOS Version Support

| iOS Version | UI Component | Behavior |
|-------------|-------------|----------|
| **iOS 26+** | WorkspaceTabBarView (Liquid Glass) | New tab bar replaces FABView |
| **iOS 16-25** | FABView (legacy) | No changes, works as before |

## Design Decisions

1. **Module Isolation:** Self-contained module for easy maintenance and testing
2. **iOS 26 Only:** Uses `@available(iOS 26, *)` to prevent compilation on older targets
3. **Permission Integration:** Respects existing `ArchiveVOData.permissions()` system
4. **Backward Compatibility:** Zero impact on iOS 16-25 users

## Dependencies

- **Foundation:** Core Swift functionality
- **Combine:** Reactive programming for state management
- **SwiftUI:** Modern UI framework
- **AuthenticationManager:** For current archive access
- **ArchivesViewModel:** For archive change notifications
- **Permission:** For access control

## Future Enhancements

- [ ] Add `.tabBarMinimizeBehavior(.onScrollDown)` for auto-hide on scroll
- [ ] Support for badge notifications on tabs
- [ ] Haptic feedback on tab selection
- [ ] Accessibility improvements (VoiceOver labels)
- [ ] Dark mode refinements

## Testing

To test this module:
1. Build the app with iOS 26+ SDK
2. Run on iOS 26+ device/simulator
3. Switch archives to test permission-based button visibility
4. Navigate between workspaces to verify smooth transitions
5. Test on iOS 16-25 to confirm legacy FAB still works

## Notes

- This is a **hackathon implementation** completed on 17 December 2025
- Part of the Liquid Glass design language adoption for iOS 26
- Maintains full backward compatibility with production iOS 16+ users
