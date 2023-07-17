//
//  TagsView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

struct TagsView: View {
    @Binding var allTags: [TagVO]
    @Binding var showAddNewTagView: Bool
    
    var body: some View {
        ScrollView {
            FlowGrid(
                data: allTags.map {$0.tagVO.name ?? ""} + ["NewTag"],
                spacing: 8,
                alignment: .leading) { item in
                    VStack {
                        if item == "NewTag" {
                            addtagView()
                        } else {
                            tagView(text: item)
                        }
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
                Button {
                    allTags.removeAll { $0.tagVO.name == text }
                } label: {
                    Image("xMarkToolbarIcon")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
        }
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.indianSaffron.opacity(0.2)))
        .foregroundColor(Color.darkBlue)
    }
    
    func addtagView() -> some View {
            VStack {
                HStack {
                    Button {
                        showAddNewTagView = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("New tag")
                                .textStyle(SmallXXRegularTextStyle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
            }
            .background(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.darkBlue.opacity(0.1), lineWidth: 1))
            .foregroundColor(Color.darkBlue)
        }
    }

struct TagsView_Previews: PreviewProvider {
    @State static var tags: [TagVO] = [
        TagVO(tagVO: TagVOData(name: "Earth",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil)),
        TagVO(tagVO: TagVOData(name: "Cinematic",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil))
    ]
    @State static var showAddNewTagView: Bool = false
    
    static var previews: some View {
        TagsView(allTags: $tags, showAddNewTagView: $showAddNewTagView)
    }
}
