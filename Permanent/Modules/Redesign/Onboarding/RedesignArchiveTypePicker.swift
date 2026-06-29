//
//  RedesignArchiveTypePicker.swift
//  Permanent
//
//  Figma "Dashboard MVP / Archive Type" (node 25369:22595), presented from the
//  Create Archive sheet's type field. Mirrors the existing, polished archive-type
//  selection used in the Share Preview flow (SharePreviewView.archiveTypeSelectionScreen):
//  the designed asset icon (`ArchiveType.onboardingDescriptionIcon`) in a rounded
//  badge + title + description + a green-checkmark selection indicator. Picking a
//  row updates the binding and dismisses. Only reachable when
//  `DashboardRedesign.isEnabled`.
//

import SwiftUI

extension ArchiveType {
    /// SF Symbol used by the Create Archive sheet's collapsed type field (the
    /// gradient icon next to the selected type). The picker rows themselves use
    /// `onboardingDescriptionIcon` (the designed asset icons).
    var redesignSFSymbol: String {
        switch self {
        case .person:        return "heart"
        case .individual:    return "person"
        case .family:        return "figure.2.and.child.holdinghands"
        case .familyHistory: return "scroll"
        case .community:     return "person.3"
        case .organization:  return "building.columns"
        case .nonProfit:     return "building.2"
        case .other:         return "square.dashed"
        case .unsure:        return "questionmark.circle"
        }
    }
}

struct RedesignArchiveTypePicker: View {
    @Binding var selected: ArchiveType
    var onClose: () -> Void = {}

    /// All types except nonProfit (folded into Organization server-side) — the
    /// same list the Share Preview archive-type screen shows.
    private var types: [ArchiveType] { ArchiveType.allCases.filter { $0 != .nonProfit } }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(types, id: \.onboardingType) { type in
                        row(type)
                        Divider()
                    }
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
    }

    private var header: some View {
        ZStack {
            Text("Archive type")
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 16))
                .tracking(-0.16)
                .foregroundColor(RedesignColor.darkBlue)
                .frame(height: 24)

            HStack {
                Color.clear.frame(width: 44, height: 44)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(RedesignColor.darkBlue)
                        .frame(width: 44, height: 44)
                        .redesignDismissGlass()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.white)
    }

    private func row(_ type: ArchiveType) -> some View {
        let isSelected = (type == selected)
        return Button {
            selected = type
            onClose()
        } label: {
            HStack(alignment: .top, spacing: 16) {
                type.onboardingDescriptionIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
                    .background(isSelected ? Color.white : Color.blue25)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 8) {
                    Text(type.onboardingType)
                        .font(.custom("Usual", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.blue900)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(type.onboardingDescription)
                        .font(.custom("Usual", size: 12))
                        .foregroundColor(.blue900)
                        .lineSpacing(1.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                selectionIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue25 : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                Image(.checkmarkGreen).frame(width: 16, height: 16)
            } else {
                Image(.accessRoleNotSelected).frame(width: 16, height: 16)
            }
        }
    }
}

#Preview {
    RedesignArchiveTypePicker(selected: .constant(.person))
}
