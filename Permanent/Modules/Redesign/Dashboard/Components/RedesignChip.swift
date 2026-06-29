//
//  RedesignChip.swift
//  Permanent
//
//  Pill chip (Frame C "What's important to you?"):
//  height 32, radius 99, padding h16. Unselected: bg #F4F6FD, 1pt border #E7E8ED,
//  label Usual Regular 12 #131B4A. Selected: dark-blue fill, white label, no border.
//

import SwiftUI

struct RedesignChip: View {
    let label: String
    var isSelected: Bool = false

    var body: some View {
        Text(label)
            .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
            .foregroundColor(isSelected ? .white : RedesignColor.darkBlue)
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(height: RedesignSpacing.chipHeight)
            .background(isSelected ? RedesignColor.darkBlue : RedesignColor.whiteGray)
            .clipShape(RoundedRectangle(cornerRadius: RedesignSpacing.chipRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RedesignSpacing.chipRadius, style: .continuous)
                    .stroke(isSelected ? Color.clear : RedesignColor.blue50, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

/// Flow layout that wraps chips onto multiple rows (gap 8). When `interactive`,
/// tapping a chip toggles its membership in `selection`.
struct RedesignChipWrap: View {
    let labels: [String]
    var spacing: CGFloat = 8
    var interactive: Bool = false
    @Binding var selection: Set<String>

    init(labels: [String],
         spacing: CGFloat = 8,
         interactive: Bool = false,
         selection: Binding<Set<String>> = .constant([])) {
        self.labels = labels
        self.spacing = spacing
        self.interactive = interactive
        self._selection = selection
    }

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(labels, id: \.self) { label in
                if interactive {
                    Button {
                        if selection.contains(label) {
                            selection.remove(label)
                        } else {
                            selection.insert(label)
                        }
                    } label: {
                        RedesignChip(label: label, isSelected: selection.contains(label))
                    }
                    .buttonStyle(.plain)
                } else {
                    RedesignChip(label: label)
                }
            }
        }
    }
}

/// Minimal flow layout (iOS 16+) used for the chip wrap.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentRowWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let added = currentRowWidth == 0 ? size.width : currentRowWidth + spacing + size.width
            if added > maxWidth, currentRowWidth > 0 {
                rows.append([size])
                currentRowWidth = size.width
            } else {
                rows[rows.count - 1].append(size)
                currentRowWidth = added
            }
        }
        let height = rows.reduce(CGFloat(0)) { partial, row in
            let rowHeight = row.map(\.height).max() ?? 0
            return partial + rowHeight
        } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: maxWidth == .infinity ? (rows.first?.map(\.width).reduce(0, +) ?? 0) : maxWidth,
                      height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxX = bounds.maxX
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    StatefulPreviewWrapper(Set<String>(["Collaboration"])) { sel in
        RedesignChipWrap(
            labels: [
                "Digital preservation", "Collaboration", "Family history",
                "Secure digital storage", "Supporting a nonprofit", "Business needs"
            ],
            interactive: true,
            selection: sel
        )
        .padding(24)
        .background(Color.white)
    }
}
