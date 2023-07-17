//
//  AddTagsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.07.2023.

import SwiftUI

struct AddTagsView: View {
    @Binding var allTags: [TagVO]
    
    var body: some View {
        ScrollView {
            FlowGrid(
                data: allTags.map {$0.tagVO.name ?? ""},
                spacing: 8,
                alignment: .leading) { item in
                    VStack {
                        tagView(text: item)
                    }
                }
        }
        .frame(maxHeight: .infinity)
    }
    
    func tagView(text: String) -> some View {
        VStack {
            HStack {
                Text(text)
                    .textStyle(SmallXXRegularTextStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .onTapGesture {
                print("tag \(text) was tapped")
            }
        }
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.indianSaffron.opacity(0.2)))
        .foregroundColor(Color.darkBlue)
    }
}

struct AddTagsView_Previews: PreviewProvider {
    @State static var tags: [TagVO] = [
        TagVO(tagVO: TagVOData(name: "Nature",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil)),
        TagVO(tagVO: TagVOData(name: "Blue Sky",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil))
    ]
    
    static var previews: some View {
        AddTagsView(allTags: $tags)
    }
}
