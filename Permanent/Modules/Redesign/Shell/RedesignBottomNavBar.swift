//
//  RedesignBottomNavBar.swift
//  Permanent
//
//  Stage 6 floating bottom navigation. A white rounded-capsule pill with two
//  tappable segments (Dashboard | Files); the selected segment renders as an
//  inner white pill with dark text and a subtle shadow, the unselected segment
//  is transparent. A SEPARATE dark-blue circular "+" FAB sits to the right and
//  is shown only when `showsAdd` is true (i.e. on the Files tab).
//
//  Lives under the Redesign module and is only reachable when
//  `DashboardRedesign.isEnabled`.
//

import SwiftUI

/// The two tabs hosted by the Stage 6 app shell.
enum RedesignShellTab: Hashable {
    case dashboard
    case files
}

struct RedesignBottomNavBar: View {
    @Binding var selection: RedesignShellTab
    /// When true, the dark-blue circular "+" FAB is shown to the right of the pill.
    var showsAdd: Bool = false
    /// Invoked when the "+" FAB is tapped.
    var onAdd: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            pill
            if showsAdd {
                addButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsAdd)
        .padding(.horizontal, 16)
    }

    // MARK: - The white capsule with two segments

    private var pill: some View {
        HStack(spacing: 4) {
            segment(.dashboard, title: "Dashboard", systemImage: "square.grid.2x2")
            segment(.files, title: "Files", systemImage: "folder")
        }
        .padding(6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        )
    }

    @ViewBuilder
    private func segment(_ tab: RedesignShellTab, title: String, systemImage: String) -> some View {
        let isSelected = selection == tab
        Button {
            guard selection != tab else { return }
            withAnimation(.easeInOut(duration: 0.2)) { selection = tab }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .regular))
                Text(title)
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
            }
            .foregroundColor(isSelected ? RedesignColor.darkBlue : RedesignColor.blue400)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(
                Group {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab == .dashboard ? "shellTabDashboard" : "shellTabFiles")
    }

    // MARK: - The separate dark-blue circular "+" FAB

    private var addButton: some View {
        Button(action: onAdd) {
            ZStack {
                Circle()
                    .fill(RedesignGradient.primaryButtonC)
                    .shadow(color: RedesignColor.darkBlue.opacity(0.30), radius: 12, x: 0, y: 6)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shellAddButton")
    }
}

#Preview("Files selected") {
    ZStack {
        RedesignColor.whiteGray.ignoresSafeArea()
        VStack {
            Spacer()
            RedesignBottomNavBar(
                selection: .constant(.files),
                showsAdd: true,
                onAdd: {}
            )
            .padding(.bottom, 24)
        }
    }
}

#Preview("Dashboard selected") {
    ZStack {
        RedesignColor.whiteGray.ignoresSafeArea()
        VStack {
            Spacer()
            RedesignBottomNavBar(
                selection: .constant(.dashboard),
                showsAdd: false,
                onAdd: {}
            )
            .padding(.bottom, 24)
        }
    }
}
