//
//  CustomPhotoLibraryView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.12.2023.

import SwiftUI
import PhotosUI

struct CustomPhotoLibraryView: View {
    @StateObject var viewModel: CustomPhotoLibraryViewModel
    @Environment(\.presentationMode) var presentationMode
    var dismissAction: ((Bool) -> Void)?
    let photoLibraryService = FetchAlbumsViewModel()
    
    private var displayedImages: [PHAsset] {
        return viewModel.selectedSegment == 0 ? viewModel.imagesInPhotos : viewModel.imagesInAlbums
    }
    
    var body: some View {
        ZStack {
            Color.whiteGray
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            VStack {
                // Custom navigation bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Picker("Select an option", selection: $viewModel.selectedSegment) {
                        Text("Photos").tag(0)
                        Text("Albums").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 132, height: 28)
                    Spacer()
                    Button("Upload") {
                        // Handle the upload action
                    }
                    .disabled(viewModel.selectedPhotos.count == .zero)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Search bar
                TextField("Search photos, people, places", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom])
                // Photos grid
                FetchAlbumsView(viewModel: viewModel, selectedSegment: $viewModel.selectedSegment)
                    .environmentObject(photoLibraryService)
                
                Spacer()
            }
            .environmentObject(photoLibraryService)
            .edgesIgnoringSafeArea(.bottom)
            
            VStack {
                // Toolbar
                Spacer()
                    floatingActionButton
                        .scaleEffect(viewModel.selectedPhotos.isEmpty ? 0 : 1)
                        .animation(.spring(), value: !viewModel.selectedPhotos.isEmpty)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private var floatingActionButton: some View {
        HStack(spacing: 8) {
            Button(action: actionAll) {
                Text(viewModel.selectedPhotos.count > 1 ? "Deselect All" : "Select All")
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical)
            .padding(.leading)
            .clipShape(Capsule())
            
            Spacer()
            
            Button(action: viewSelected) {
                Text("View Selected")
                    .multilineTextAlignment(.trailing)
            }
            .padding(.leading, 10)
            .clipShape(Capsule())
            
            Text("  \(viewModel.selectedPhotos.count)  ")
                .frame(height: 24)
                .background(Color.lightGray)
                .foregroundColor(Color.black)
                .clipShape(Capsule())
        }
        .padding(.horizontal)
        .background(BlurView(style: .systemMaterial))
        .cornerRadius(30)
        .padding(.horizontal, 30)
        .shadow(radius: 10)
        .frame(height: 48, alignment: .center)
        .padding(.bottom, 20)
    }
    
    private func dismiss() {
        dismissAction?(viewModel.hasUpdates)
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func actionAll() {
    }
    
    func viewSelected() {
    }
    
    struct BlurView: UIViewRepresentable {
        var style: UIBlurEffect.Style
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            return UIVisualEffectView(effect: UIBlurEffect(style: style))
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: style)
        }
    }
}

#Preview {
    CustomPhotoLibraryView(viewModel: CustomPhotoLibraryViewModel())
}
