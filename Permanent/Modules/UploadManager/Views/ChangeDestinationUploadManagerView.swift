//
//  ChangeDestinationUploadManagerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.10.2023.

import SwiftUI

struct ChangeDestinationUploadManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ChangeDestinationUploadManagerViewModel
    @State var isArchiveMenuExpanded: Bool = false
    
    var body: some View {
        CustomNavigationView {
            VStack(alignment: .leading, spacing: 24) {
                dropDownList
                if !isArchiveMenuExpanded {
                    privateFiles
                    sharedFiles
                    publicFiles
                }
            }
            .padding(.horizontal, 24)
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
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Text("Save")
                    .foregroundColor(.white)
            }
        }
    }
    
    var dropDownList: some View {
        ZStack {
            Rectangle()
              .foregroundColor(.clear)
              .background(Color(red: 0.96, green: 0.96, blue: 0.99))
              .frame(height: 90 )
              .padding(.horizontal, -30)
              .padding(.top, 0)
            HStack(spacing: 16) {
                Image(.gradientFolder)
                Text("The \(viewModel.getCurrentArchiveName()) Archive")
                    .textStyle(SmallSemiBoldTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.downArrowUpload)
            }
            .foregroundColor(.clear)
        }

    }
    
    var privateFiles: some View {
        Button(action: {
            //Add action
        }, label: {
            HStack(spacing: 16) {
                Image(.privateFilesLogo)
                Text("Private Files")
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.rightArrowUpload)
            }
        })
    }
    
    var sharedFiles: some View {
            Button(action: {
                //Add action
            }, label: {
            HStack(spacing: 16) {
                Image(.sharedFilesLogo)
                Text("Shared Files")
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.rightArrowUpload)
            }
        })
    }
    
    var publicFiles: some View {
        Button(action: {
            //Add action
        }, label: {
            HStack(spacing: 16) {
                Image(.publicFilesLogo)
                Text("Public Files")
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(.black)
                Spacer()
                Image(.rightArrowUpload)
            }
        })
    }
}

#Preview {
    ChangeDestinationUploadManagerView(viewModel: ChangeDestinationUploadManagerViewModel(currentArchive: nil))
}
