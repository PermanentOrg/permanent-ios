//
//  TagsView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

struct TagsView: View {
    @ObservedObject var viewModel: FilesMetadataViewModel
    @Binding var showAddNewTagView: Bool

    var body: some View {
        ScrollView {
            FlowGrid(
                data: viewModel.allTags.map {$0.tagVO.name ?? ""} + ["NewTag"],
                spacing: 8,
                alignment: .leading) { item in
                    VStack {
                        if item == "NewTag" {
                            addtagView()
                        } else {
                            TagView(text: item, viewModel: viewModel)
                        }
                    }
                }
        }
        .frame(maxHeight: .infinity)
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

struct TagView: View {
    let text: String
    @ObservedObject var viewModel: FilesMetadataViewModel
    @State var isLoading: Bool = false
    var tagColor = Color.paleOrange.opacity(0.2)
    var fullTagColor = Color.indianSaffron.opacity(0.2)
    @State var showLineBorder: Bool = true

    init(text: String, viewModel: FilesMetadataViewModel) {
        self.text = text
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                Text(text)
                    .textStyle(SmallXXRegularTextStyle())
                Button {
                    viewModel.unassignTag(tagName: text, isLoading: $isLoading)
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 10, height: 10)
                    } else {
                        Image("xMarkToolbarIcon")
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
        }
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(viewModel.isTagInAllFiles(text) ? fullTagColor : tagColor))
        .foregroundColor(Color.darkBlue)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color(red: 1, green: 0.9, blue: 0.8), lineWidth: viewModel.isTagInAllFiles(text) ? 0 : 1)
        )
        .onTapGesture {
            viewModel.assignTagToAll(tagName: text, isLoading: $isLoading)
        }
    }
}

struct TagsView_Previews: PreviewProvider {
    @State static var tags: [TagVO] = [
        TagVO(tagVO: TagVOData(name: "Earth",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil)),
        TagVO(tagVO: TagVOData(name: "Cinematic",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil))
    ]
    @State static var showAddNewTagView: Bool = false
    @State static var removeTagName: String? = nil
    @ObservedObject static var viewModel = FilesMetadataViewModel(files: [])
    
    static var previews: some View {
        TagsView(viewModel: viewModel, showAddNewTagView: $showAddNewTagView)
    }
}
