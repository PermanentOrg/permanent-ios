//
//  UploadManagerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2023.

import SwiftUI
import Photos

struct UploadManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: UploadManagerViewModel
    
    var body: some View {
        CustomNavigationView(content: {
            VStack(spacing: 1) {
                Spacer(minLength: 18)
                uploadToSection
                archiveSection
                folderSection
                assetSection
            }
            .onAppear(perform: {
                viewModel.getDescriptors()
            })
            .padding(.horizontal, 6)
            .navigationBarTitle("Permanent", displayMode: .inline)
        }, leftButton: {
            backButton
        }, rightButton: {
            uploadButton
        })
    }
    
    var uploadToSection: some View {
        Group {
            HStack {
                if #available(iOS 16, *) {
                    Text("Upload To".uppercased())
                        .textStyle(SmallXXRegularTextStyle())
                        .kerning(0.48)
                        .foregroundColor(Color.middleGray)
                } else {
                    Text("Upload To".uppercased())
                        .textStyle(SmallXXRegularTextStyle())
                        .foregroundColor(Color.middleGray)
                }
                Spacer()
                Button(action: {
                    //add action
                }, label: {
                    HStack(spacing: 1) {
                        Image(.chooseFolderArrow)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.darkBlue)
                        Text("Choose...")
                            .textStyle(SmallSemiBoldTextStyle())
                            .foregroundColor(Color.darkBlue)
                            .multilineTextAlignment(.trailing)
                    }
                })
            }
            .padding()
        }
    }
    
    var archiveSection: some View {
        HStack {
            Image(.gradientFolder)
                .frame(width: 40, height: 40)
            Text("The \(viewModel.getCurrentArchiveName()) Archive")
                .textStyle(SmallSemiBoldTextStyle())
                .foregroundColor(Color.black)
                .multilineTextAlignment(.leading)
                .padding(.leading, 10)
                .lineLimit(1)
            Spacer()
            ZStack {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 54, height: 18)
                    .background(Color(red: 0.91, green: 0.8, blue: 0.91))
                    .cornerRadius(4)
                if #available(iOS 16, *) {
                    Text("\(viewModel.getCurrentArchivePermission())".uppercased())
                        .textStyle(SmallXXXXXXRegularTextStyle())
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.darkBlue)
                        .frame(width: 40, height: 15)
                        .kerning(0.8)
                        .padding(.bottom, 2)
                } else {
                    Text("\(viewModel.getCurrentArchivePermission())".uppercased())
                        .textStyle(SmallXXXXXXRegularTextStyle())
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.darkBlue)
                        .frame(width: 40, height: 15)
                        .padding(.bottom, 2)
                }
            }
        }
        .padding(.top)
        .padding(.horizontal)
    }
    
    var folderSection: some View {
        Group {
            HStack {
                Image(.lineBetweenFolders)
                    .frame(width: 70, height: 40)
                Spacer()
            }
            .padding(.top, -8)
            HStack {
                Image(.purpleFolder)
                    .frame(width: 40, height: 40)
                HStack {
                    Text("\(viewModel.getCurrentFolderPath())")
                        .textStyle(SmallSemiBoldTextStyle())
                        .foregroundColor(Color.lightGray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Text("\(viewModel.getCurrentFolder())")
                        .textStyle(SmallSemiBoldTextStyle())
                        .foregroundColor(Color.middleGray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .padding(.leading, -7)
                }
                .padding(.leading, 10)
                .padding(.bottom, 5)
                Spacer()
            }
            .padding(.top, -5)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    var assetSection: some View {
        Group {
            Rectangle()
                .fill(Color.lightGray)
                .frame(height: 1)
                .edgesIgnoringSafeArea(.horizontal)
                .padding(.horizontal, -15)
            Spacer(minLength: 6)
            HStack {
                Text("\(viewModel.numberOfAssets)".uppercased())
                    .textStyle(SmallXXXRegularTextStyle())
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.middleGray)
                Spacer()
                Button(action: {
                    // Insert action here
                }) {
                    HStack {
                        Image(.adjustTicket)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.darkBlue)
                            .padding(.trailing, -5)
                        Text("Adjust metadata")
                            .textStyle(SmallSemiBoldTextStyle())
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.darkBlue)
                    }
                }
            }
            .padding()
            assetList
            Spacer()
        }
    }
    
    var assetList: some View {
        ScrollView(showsIndicators: false, content: {
            LazyVStack(spacing: 24) {
                ForEach(viewModel.assetURLs, id: \.self) { descriptor in
                    HStack {
                        Image(uiImage: descriptor.image ?? UIImage(systemName: "photo")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipped()
                        VStack(alignment: .leading) {
                            Text(descriptor.name)
                                .textStyle(SmallRegularTextStyle())
                                .lineLimit(1)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.middleGray)
                            Text("\(descriptor.url.fileSizeString)")
                                .textStyle(SmallXXXRegularTextStyle())
                                .lineLimit(1)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.lightGray)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.deleteAsset(at: descriptor)
                        }) {
                            Image(.removeItem)
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 8)
                    }
                }
            }
        })
        .padding(.top, 10)
        .padding(.horizontal)
    }
    
    var backButton: some View {
        Button(action: {
            dismissView()
        }) {
            HStack {
                Text("Back")
                    .foregroundColor(.white)
            }
        }
    }
    
    var uploadButton: some View {
        Button(action: {
            dismissViewWithAssets()
        }) {
            HStack {
                Text("Upload")
                    .foregroundColor(.white)
            }
        }
    }

    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }

    func dismissViewWithAssets() {
        viewModel.completionHandler?(viewModel.assets)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    UploadManagerView(viewModel: UploadManagerViewModel(assets: [], currentArchive: nil, folderNavigationStack: nil))
}
