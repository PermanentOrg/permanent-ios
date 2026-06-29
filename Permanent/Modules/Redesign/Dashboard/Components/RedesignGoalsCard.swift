//
//  RedesignGoalsCard.swift
//  Permanent
//
//  Frame C — "Chart your path to success" goals widget. Purple gradient card
//  with a trophy header, multi-select goal chips, and a Remind/Save footer.
//
//  Selection is shown by the pill style alone (no checkmark): selected = white
//  fill + bold gradient label; unselected = translucent fill + white label.
//  Each chip reserves the width of its BOLD (selected) text, so toggling never
//  changes the chip's footprint — the grid keeps its natural wrap and never moves.
//

import SwiftUI

struct RedesignGoalsCard: View {
    let goals: [String]
    @Binding var selected: Set<String>
    var onRemindLater: () -> Void = {}
    var onSave: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            divider
            RedesignGoalChipWrap(goals: goals, selected: $selected)
            divider
            footer
        }
        .padding(24)
        .background(RedesignGradient.purpleGoalsCard)
        .clipShape(RoundedRectangle(cornerRadius: RedesignSpacing.cardRadius, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle().fill(RedesignColor.whiteGray)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(RedesignGradient.goalChipSelected)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text("Chart your path to success")
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                    .foregroundColor(.white)
                    .frame(height: 24, alignment: .leading)
                Text("We want to help you reach your goals")
                    .font(.custom(FontName.usualRegular.rawValue, fixedSize: 12))
                    .foregroundColor(.white.opacity(0.64))
                    .frame(height: 16, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
    }

    private var footer: some View {
        HStack {
            Button(action: onRemindLater) {
                Text("Remind me later")
                    .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                    .foregroundColor(.white.opacity(0.64))
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onSave) {
                Text("Save goals")
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Goal chips on the purple card. Tap toggles selection. No checkmark — the chip
/// reserves its bold (selected) width so toggling regular↔bold never reflows.
struct RedesignGoalChipWrap: View {
    let goals: [String]
    @Binding var selected: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(goals, id: \.self) { goal in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        if selected.contains(goal) {
                            selected.remove(goal)
                        } else {
                            selected.insert(goal)
                        }
                    }
                } label: {
                    goalChip(goal, isSelected: selected.contains(goal))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func goalChip(_ label: String, isSelected: Bool) -> some View {
        ZStack {
            // Invisible sizing layer = the bold (selected) label, so the chip's
            // footprint is constant whether regular or bold → no reflow on toggle.
            chipText(label, selected: true).hidden()
            chipText(label, selected: isSelected)
        }
        .padding(.horizontal, 16)
        .frame(height: RedesignSpacing.chipHeight)
        .background(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.white.opacity(0.08)))
        .clipShape(RoundedRectangle(cornerRadius: RedesignSpacing.chipRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RedesignSpacing.chipRadius, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func chipText(_ label: String, selected: Bool) -> some View {
        Text(label)
            .font(.custom(selected ? FontName.usualMedium.rawValue : FontName.usualRegular.rawValue, fixedSize: 12))
            .foregroundStyle(selected ? AnyShapeStyle(RedesignGradient.goalChipSelected) : AnyShapeStyle(Color.white))
            .lineLimit(1)
    }
}

#Preview {
    StatefulPreviewWrapper(Set(["Share privately", "Build an archive with someone"])) { sel in
        RedesignGoalsCard(
            goals: [
                "Publish a legacy", "Plan my digital legacy", "Share privately",
                "Preserve memories", "Digitize my materials",
                "Build an archive with someone", "Organize my materials"
            ],
            selected: sel
        )
        .padding(24)
        .background(RedesignColor.whiteGray)
    }
}
