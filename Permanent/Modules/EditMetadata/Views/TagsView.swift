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
    @State var unassignWasTapped: Bool = false
    @State var tagColor: Color = Color.paleOrange.opacity(0.2)
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
                    unassignWasTapped = true
                    viewModel.unassignTag(tagName: text, completion: { _ in
                        unassignWasTapped = false
                    })
                } label: {
                    if unassignWasTapped {
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
            .fill(tagColor))
        .foregroundColor(Color.darkBlue)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color(red: 1, green: 0.9, blue: 0.8), lineWidth: showLineBorder ? 1 : 0)
        )
        .onAppear {
            if viewModel.filteredAllTags.contains(where: { $0.tagVO.name == text }) {
                tagColor = Color.indianSaffron.opacity(0.2)
                showLineBorder = false
            }
        }
        .onTapGesture {
            print("tapped \(text) tag")
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
