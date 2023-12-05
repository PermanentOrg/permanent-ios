//
//  AddTagsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.07.2023.

import SwiftUI

struct AddTagsView: View {
    @Binding var allTags: [TagVO]
    @Binding var addedTags: [TagVO]
    
    var body: some View {
        ScrollView {
            FlowGrid(
                data: allTags,
                spacing: 8,
                alignment: .leading) { item in
                    VStack {
                        tagView(tag: item)
                    }
                }
        }
        .frame(maxHeight: .infinity)
    }
    
    func tagView(tag: TagVO) -> some View {
        VStack {
            HStack {
                Text(tag.tagVO.name ?? "")
                    .textStyle(SmallXXRegularTextStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .onTapGesture {
                if addedTags.contains(where: { $0.tagVO.name == tag.tagVO.name }) {
                    addedTags.removeAll(where: { $0.tagVO.name == tag.tagVO.name })
                } else {
                    addedTags.append(tag)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(addedTags.contains(where: { $0.tagVO.name == tag.tagVO.name }) ? Color.indianSaffron.opacity(0.2) : Color.paleOrange.opacity(0.2)))
        .foregroundColor(Color.darkBlue)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color(red: 1, green: 0.9, blue: 0.8), lineWidth: addedTags.contains(where: { $0.tagVO.name == tag.tagVO.name }) ? 0 : 1)
        )
    }
}

struct AddTagsView_Previews: PreviewProvider {
    @State static var tags: [TagVO] = [
        TagVO(tagVO: TagVOData(name: "Nature",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil)),
        TagVO(tagVO: TagVOData(name: "Blue Sky",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil))
    ]
    @State static var addedTags: [TagVO] = []
    
    static var previews: some View {
        AddTagsView(allTags: $tags, addedTags: $addedTags)
    }
}
