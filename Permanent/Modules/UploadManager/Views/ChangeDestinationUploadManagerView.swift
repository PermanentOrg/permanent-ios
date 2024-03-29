//
//  ChangeDestinationUploadManagerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.10.2023.

import SwiftUI

struct ChangeDestinationUploadManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ChangeDestinationUploadManagerViewModel
    @State private var isOptionsPresented: Bool = false
    
    let haveChanges: (_ changedArchive: ArchiveVOData?) -> Void
    
    var body: some View {
        CustomNavigationView {
            VStack(alignment: .leading, spacing: 24) {
                dropDownList
                if !isOptionsPresented {
                    privateFiles
                    sharedFiles
                    publicFiles
                }
            }
            .padding(.top, 0)
            .navigationBarTitle("Choose Folder", displayMode: .inline)
        } leftButton: {
            backButton
        } rightButton: {
            saveButton
        }
    }
    
    var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Text("Back")
                    .foregroundColor(.white)
            }
        }
    }
    
    var saveButton: some View {
        Button(action: {
            if let changedArchive = viewModel.changedArchive {
                viewModel.changeArchive(changedArchive) { result, error in
                    if error == nil {
                        self.haveChanges(viewModel.currentArchive())
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            HStack {
                Text("Save")
                    .foregroundColor(.white)
            }
        }
    }
    
    var dropDownList: some View {
        VStack {
            ArchiveDropdownMenu(
                isOptionsPresented: self.$isOptionsPresented,
                selectedOption: self.$viewModel.archiveSelected,
                placeholder: "Select an archive",
                options: viewModel.archivesList) { selectedArchive in
                    handleArchiveSelection(selectedArchive)
                }
        }
        .foregroundColor(.clear)
    }
    
    private func handleArchiveSelection(_ archive: ArchiveDropdownMenuOption) {
        viewModel.changedArchive = archive
        viewModel.updateArchivesList()
        self.isOptionsPresented = false
    }
    
    var privateFiles: some View {
        Button(action: {
            ///Add action
        }, label: {
            HStack(spacing: 16) {
                Image(.privateFilesLogo)
                Text("Private Files")
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.rightArrowUpload)
            }
            .padding(.horizontal, 24)
        })
    }
    
    var sharedFiles: some View {
            Button(action: {
                ///Add action
            }, label: {
            HStack(spacing: 16) {
                Image(.sharedFilesLogo)
                Text("Shared Files")
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.rightArrowUpload)
            }
            .padding(.horizontal, 24)
        })
    }
    
    var publicFiles: some View {
        Button(action: {
            ///Add action
        }, label: {
            HStack(spacing: 16) {
                Image(.publicFilesLogo)
                Text("Public Files")
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.rightArrowUpload)
            }
            .padding(.horizontal, 24)
        })
    }
}

#Preview {
    ChangeDestinationUploadManagerView(viewModel: ChangeDestinationUploadManagerViewModel(currentArchive: nil), haveChanges: { _ in })
}
