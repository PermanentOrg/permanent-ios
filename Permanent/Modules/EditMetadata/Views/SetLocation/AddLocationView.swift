//
//  AddLocationView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 24.08.2023.

import SwiftUI
import CoreLocation
import MapKit

struct AddLocationView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var text: String = ""
    @State var isPresented: Bool = false
    @State var showMap: Bool = true
    
    @ObservedObject var viewModel: AddLocationViewModel
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack(alignment: .topLeading) {
                    if showMap {
                        MapView(coordinates: $viewModel.selectedCoordinates)
                            .edgesIgnoringSafeArea(.all)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    }
                    
                    VStack(spacing: 20) {
                        VStack {
                            let rightView = AnyView(Image(systemName: "xmark")
                                .onTapGesture {
                                    viewModel.searchText = ""
                                })
                            TextField("Search..", text: $viewModel.searchText, onEditingChanged: { isEditing in
                                withAnimation {
                                    showMap = !isEditing
                                }
                            })
                            .modifier(SmallXXRegularTextStyle())
                            .textFieldStyle(CustomTextFieldStyle(
                                leftView: AnyView(Image(systemName: "magnifyingglass")),
                                rightView: rightView))
                        }
                        .background(Color.white)
                        .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 8)
                        
                        if !showMap {
                            locationsList
                                .padding(5)
                        }
                        Spacer()
                        
                        bottomButtons
                    }
                    .background(Color.clear)
                    .padding()
                }
                .navigationBarTitle("Add location", displayMode: .inline)
                .navigationBarItems(leading: Image("metadataLocations")
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24))
            }
            if viewModel.showConfirmation {
                CustomDialogView(isActive: $viewModel.showConfirmation, title: "New location", message: "Are you sure you want set a new location for selected items?", buttonTitle: "Set location") {
                    viewModel.update { success in
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .frame(width: 294)
            }
        }
    }
    
    var locationsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20, content: {
                ForEach(viewModel.searchedLocations, id: \.self) { item in
                    HStack(spacing: 16) {
                        VStack {
                            Image("marker")
                                .frame(width: 12)
                        }
                        .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                        .frame(width: 32, height: 32)
                        VStack(alignment: .leading, content: {
                            Text(item.attributedPrimaryText.string)
                                .foregroundColor(.middleGray)
                                .textStyle(SmallRegularTextStyle())
         
                            Text("\(item.attributedSecondaryText?.string ?? "")")
                                .foregroundColor(.lightGray)
                                .textStyle(SmallXXXXRegularTextStyle())
                            
                        })
                    }
                    .onTapGesture {
                        viewModel.selectedPlace = item
                        viewModel.fetchPlace()
                        dismissKeyboard()
                    }
                }
            })
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
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Set location")
                }
            }
            .buttonStyle(CustomButtonStyle(
                backgroundColor: viewModel.locnVO == nil ? Color(red: 0.77, green: 0.77, blue: 0.82) : .darkBlue,
                foregroundColor: .white))
            .disabled(viewModel.locnVO == nil)
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AddLocationView_Previews: PreviewProvider {
    static var previews: some View {
        AddLocationView(viewModel: AddLocationViewModel(selectedFiles: [], commonLocation: nil))
    }
}
