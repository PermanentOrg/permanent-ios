//
//  FileInfoRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// A row of the Info tab. A boxed name or description is typed in place and committed when the field loses focus;
/// a boxed date or location reports a tap. A plain row is text only.
struct FileInfoRow: View {
    let model: FileInfoRowModel
    /// Gets the typed text and answers whether it was saved, so an unsaved text goes back to the value.
    var onCommit: ((String, @escaping (Bool) -> Void) -> Void)?
    var onTap: (() -> Void)?

    @State private var draft: String
    @FocusState private var isEditing: Bool
    @ScaledMetric(relativeTo: .caption) private var labelLineHeight = FileInfoRowModel.labelLineHeight
    @ScaledMetric(relativeTo: .subheadline) private var valueLineHeight = FileInfoRowModel.valueLineHeight
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = FileInfoRowModel.iconSize

    init(model: FileInfoRowModel, onCommit: ((String, @escaping (Bool) -> Void) -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.model = model
        self.onCommit = onCommit
        self.onTap = onTap
        _draft = State(initialValue: model.value ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FileInfoRowModel.labelGap) {
            Text(model.title)
                .font(FileInfoRowModel.labelFont)
                .foregroundColor(.white)
                .frame(minHeight: labelLineHeight)
            value
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black)
        // One element per row; the field and its icon come apart only while the field is being edited.
        .accessibilityElement(children: isEditing ? .contain : .ignore)
        .accessibilityLabel(model.accessibilityLabel)
        .accessibilityHint(model.accessibilityHint ?? "")
        .accessibilityAddTraits(model.isButton ? .isButton : [])
        .accessibilityAction { activate() }
        .onChange(of: model.value) { draft = $0 ?? "" }
        .onChange(of: isEditing) { editing in
            if !editing { commit() }
        }
    }

    @ViewBuilder private var value: some View {
        switch model.style {
        case .plain:
            valueText

        case .boxed:
            box
        }
    }

    @ViewBuilder private var box: some View {
        if model.isTyped {
            boxed(HStack(spacing: FileInfoRowModel.boxPadding) {
                TextField("", text: $draft, prompt: Text(model.placeholder).foregroundColor(placeholderColor))
                    .font(FileInfoRowModel.valueFont)
                    .foregroundColor(.white)
                    .tint(.white)
                    .focused($isEditing)
                    .submitLabel(.done)
                    .onSubmit { isEditing = false }
                    .frame(minHeight: valueLineHeight)
                Button { isEditing = true } label: { icon }
                    .accessibilityLabel(model.accessibilityHint ?? "")
            })
        } else {
            Button { onTap?() } label: {
                boxed(HStack(spacing: FileInfoRowModel.boxPadding) {
                    valueText
                    icon
                })
            }
            .buttonStyle(.plain)
        }
    }

    /// The box around a boxed value: padding inside a rounded 1 pt border.
    private func boxed<Content: View>(_ content: Content) -> some View {
        content
            .padding(FileInfoRowModel.boxPadding)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: FileInfoRowModel.boxCornerRadius)
                    .strokeBorder(Color.white.opacity(FileInfoRowModel.borderOpacity), lineWidth: 1)
            )
    }

    private var valueText: some View {
        Text(model.text)
            .font(FileInfoRowModel.valueFont)
            .foregroundColor(model.isSet ? .white : placeholderColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: valueLineHeight, alignment: .leading)
    }

    private var icon: some View {
        Image(systemName: model.iconName ?? "plus")
            .font(.system(size: 17))
            .foregroundColor(.white)
            .frame(width: iconSize, height: iconSize)
    }

    private var placeholderColor: Color {
        Color.white.opacity(FileInfoRowModel.placeholderOpacity)
    }

    /// What a VoiceOver double tap does on a boxed row: typed rows start editing, the others open their screen.
    private func activate() {
        guard model.isButton else { return }
        if model.isTyped {
            isEditing = true
        } else {
            onTap?()
        }
    }

    private func commit() {
        guard model.isTyped, let onCommit else { return }
        onCommit(draft) { saved in
            if !saved { draft = model.value ?? "" }
        }
    }
}
