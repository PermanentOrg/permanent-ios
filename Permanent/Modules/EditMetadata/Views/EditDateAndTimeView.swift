//
//  EditDateAndTimeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.08.2023.

import SwiftUI

struct EditDateAndTimeView: View {
    @StateObject var viewModel: EditDateAndTimeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .navigationBarTitle("Add date and time", displayMode: .inline)
                .navigationBarItems(leading: Image("editFilenames")
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24))
            }
            VStack {
                if #available(iOS 16.0, *) {
                    DatePicker("Select a date", selection: $viewModel.selectedDate, in: viewModel.startingDate...viewModel.endingDate)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .padding()
                    .tint(.darkBlue)
                } else {
                    DatePicker("Select a date", selection: $viewModel.selectedDate, in: viewModel.startingDate...viewModel.endingDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .padding()
                        .accentColor(.darkBlue)
                }
                Spacer()
                bottomButtons
            }
            .padding(.top, 50)
            .onChange(of: viewModel.changesWereSaved, perform: { newValue in
                if newValue {
                    viewModel.changesWereSaved = false
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .onChange(of: viewModel.changesConfirmed) { newValue in
                if newValue {
                    viewModel.applyChanges()
                }
            }
            .sheet(isPresented: $viewModel.showConfirmation) {
                CustomAlertView(confirmed: $viewModel.changesConfirmed, title: "New Date & Time", context: "Are you sure you want set a new date & time for selected items?", confirmButtonText: "Set date and time")
                    .frame(width: 294)
                    .clearModalBackground()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                    viewModel.showAlert = false
                })
            }
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
                    Text("Apply changes")
                }
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .darkBlue, foregroundColor: .white))
        }
        .padding()
    }
}

struct EditDateAndTimeView_Previews: PreviewProvider {
    @State static var hasUpdates: Bool = false
    static var previews: some View {
        EditDateAndTimeView(viewModel: EditDateAndTimeViewModel(selectedFiles: [], hasUpdates: $hasUpdates))
    }
}
