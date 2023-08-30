//
//  AddLocationView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 24.08.2023.

import SwiftUI
import CoreLocation
import MapKit

struct City: Identifiable, Hashable {
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    let id: String
    let title: String
    let subtitle: String
    let distance: String?
    var coordinate: CLLocationCoordinate2D?
}

struct AddLocationView: View {
    @State var text: String = ""
    @State var isPresented: Bool = false
    @State var showMap: Bool = true
    
    @ObservedObject var viewModel = AddLocationViewModel()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if showMap {
                MapView(coordinates: $viewModel.selectedCoordinates)
                .edgesIgnoringSafeArea(.all)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }

            VStack(spacing: 20) {
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
                
                if !showMap {
                    locationsList
                        .padding(5)
                    Spacer()
                }
            }
            .background(Color.white)
            .padding()
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
                            Text(item.title)
                                .foregroundColor(.middleGray)
                                .textStyle(SmallRegularTextStyle())
                            if let distance = item.distance {
                                Text("\(distance) . \(item.subtitle)")
                                    .foregroundColor(.lightGray)
                                    .textStyle(SmallXXXXRegularTextStyle())
                            } else {
                                Text("\(item.subtitle)")
                                    .foregroundColor(.lightGray)
                                    .textStyle(SmallXXXXRegularTextStyle())
                            }
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
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AddLocationView_Previews: PreviewProvider {
    static var previews: some View {
        AddLocationView()
    }
}
