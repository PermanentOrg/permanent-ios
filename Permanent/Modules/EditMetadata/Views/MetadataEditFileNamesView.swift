//
//  MetadataEditFileNames.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2023.

import SwiftUI
import SDWebImageSwiftUI

struct MenuItem: Hashable {
    var name: String
    var image: UIImage
}

struct MetadataEditFileNamesView: View {
    @ObservedObject var viewModel: MetadataEditFileNamesViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var showEditFilenames: Binding<Bool>?
    
    var replaceViewModel: ReplaceFilenameViewModel!
    var appendViewModel: AppendFilenameViewModel!
    var sequenceViewModel: SequenceFilenameViewModel!

    @State private var selectedItem: MenuItem? = MenuItem(name: "Replace", image: UIImage(named: "metadataReplace")!)
    private var menuItems: [MenuItem] = [
        MenuItem(name: "Replace", image: UIImage(named: "metadataReplace")!),
        MenuItem(name: "Append", image: UIImage(named: "metadataAppend")!),
        MenuItem(name: "Sequence", image: UIImage(named: "metadataSequence")!),
    ]

    init(viewModel: MetadataEditFileNamesViewModel) {
        self.viewModel = viewModel
        
        self.replaceViewModel = ReplaceFilenameViewModel(selectedFiles: self.viewModel.selectedFiles, fileNamePreview: $viewModel.fileNamePreview)
        self.appendViewModel = AppendFilenameViewModel(selectedFiles: self.viewModel.selectedFiles, fileNamePreview: $viewModel.fileNamePreview)
        self.sequenceViewModel = SequenceFilenameViewModel(selectedFiles: self.viewModel.selectedFiles, fileNamePreview: $viewModel.fileNamePreview)
    }
    
    var body: some View {
        ZStack {
            ZStack {
                NavigationView {
                    VStack {
                        CustomSegmentedControl(selectedItem: $selectedItem, items: menuItems)
                        
                        if selectedItem?.name == "Replace" {
                            ReplaceFilenameView(viewModel: replaceViewModel)
                        }
                        if selectedItem?.name == "Append" {
                            AppendFilenameView(viewModel: appendViewModel)
                        }
                        if selectedItem?.name == "Sequence" {
                            SequenceFilenameView(viewModel: sequenceViewModel)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                    .navigationBarTitle("Edit file names", displayMode: .inline)
                    .navigationBarItems(leading: Image("editFilenames")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24))
                }
                .padding(.bottom, 85)
                VStack {
                    Spacer()
                    previewSection
                        .padding(.horizontal, 10)
                    bottomButtons
                        .padding(.horizontal, 10)
                }
                .onAppear {
                    setCurrentViewModel(editViewModel: replaceViewModel)
                }
                .onChange(of: selectedItem) { newValue in
                    switch newValue?.name {
                    case "Replace":
                        setCurrentViewModel(editViewModel: replaceViewModel)
                    case "Append":
                        setCurrentViewModel(editViewModel: appendViewModel)
                    case "Sequence":
                        setCurrentViewModel(editViewModel: sequenceViewModel)
                    default:
                        break
                    }
                }
                .onChange(of: viewModel.changesWereSaved, perform: { newValue in
                    if newValue {
                        viewModel.changesWereSaved = false
                        presentationMode.wrappedValue.dismiss()
                    }
                })
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                        viewModel.showAlert = false
                    })
                }
            }
            if viewModel.showConfirmation {
                CustomDialogView(isActive: $viewModel.showConfirmation, title: "Modify file \(viewModel.selectedFiles.count > 1 ? "names" : "name")", message: "Are you sure you want to find and replace these \(viewModel.selectedFiles.count) file \(viewModel.selectedFiles.count > 1 ? "names" : "name")?", buttonTitle: "Modify") {
                    viewModel.applyChanges()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    func setCurrentViewModel(editViewModel: MetadataEditFilenamesProtocol) {
        viewModel.currentViewModel = editViewModel
    }
    
    var previewSection: some View {
        VStack {
            HStack {
                Text("Preview".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(.lightGray)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 286, height: 1)
                    .background(Color.lightGray)
            }
            HStack(spacing: 16) {
                Rectangle()
                .foregroundColor(.clear)
                .frame(width: 40, height: 40)
                .background(
                    WebImage(url: URL(string: viewModel.imagePreviewURL))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipped()
                )
                VStack(alignment: .leading) {
                    Text(viewModel.fileNamePreview ?? "")
                        .foregroundColor(.middleGray)
                        .textStyle(SmallRegularTextStyle())
                        .multilineTextAlignment(.leading)
                    Text(viewModel.fileSizePreview ?? "")
                        .textStyle(SmallXXXRegularTextStyle())
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
    
    var bottomButtons: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .galleryGray, foregroundColor: .darkBlue))
            Spacer(minLength: 15)
            Button {
                viewModel.showConfirmation = true
                //viewModel.applyChanges()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Apply changes")
                }
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .darkBlue, foregroundColor: .white))
        }
        .padding()
    }
}

struct MetadataEditFileNames_Previews: PreviewProvider {
    @State static var hasUpdates: Bool = true
    
    static var previews: some View {
        let file = FileModel(model: FolderVOData(folderID: 22, archiveNbr: nil, archiveID: 22, displayName: "TestFile", displayDT: nil, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, voDescription: nil, special: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil, thumbURL200: nil, thumbURL500: "https://img.freepik.com/free-photo/bright-yellow-fire-blazing-against-night-sky-generated-by-ai_188544-11620.jpg?t=st=1690878101~exp=1690881701~hmac=103cd63a2a40c4feeda570cad19c0c3cc8de275d6d6c2731ee33c3310669f67c&w=2000", thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, pathAsFolderLinkID: nil, shareDT: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, parentDisplayName: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, tagVOS: nil, sharedArchiveVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVO: nil, returnDataSize: nil, archiveArchiveNbr: nil, accessVOS: nil, posStart: nil, posLimit: nil, searchScore: nil, createdDT: nil, updatedDT: nil))
        MetadataEditFileNamesView(viewModel: MetadataEditFileNamesViewModel(selectedFiles: [file], hasUpdates: $hasUpdates))
    }
}
