//
//  TagsView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

struct TagsView: View {
    @Binding var allTags: [TagVOData]
    
    var body: some View {
        ScrollView {
            FlowGrid(
                data: allTags.map {$0.name ?? ""} + ["NewTag"],
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
                    allTags.removeAll { $0.name == text }
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
                    allTags.insert(TagVOData(name: "Item", status: nil, tagId: nil, type: nil, createdDT: nil, updatedDT: nil), at:  allTags.count)
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
    @State static var tags: [TagVOData] = []
    
    static var previews: some View {
        TagsView(allTags: $tags)
    }
}
