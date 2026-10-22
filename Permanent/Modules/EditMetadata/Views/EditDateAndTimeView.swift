//
//  EditDateAndTimeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.08.2023.
//

import SwiftUI

struct EditDateAndTimeView: View {
    @StateObject var viewModel: EditDateAndTimeViewModel
    @Environment(\.presentationMode) var presentationMode
    /// Set when UIKit presents the screen; it is told whether the date was saved.
    var onClose: ((Bool) -> Void)?
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .darkBarSheet(title: "AddDateAndTime".localized()) { close(saved: false) }
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
                    close(saved: true)
                }
            })
            .onChange(of: viewModel.changesConfirmed) { newValue in
                if newValue {
                    viewModel.applyChanges()
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                    viewModel.showAlert = false
                })
            }
            if viewModel.showConfirmation {
                CustomDialogView(isActive: $viewModel.showConfirmation, title: "ChangeDateAndTime".localized(), message: confirmationMessage, buttonTitle: "Modify") {
                    viewModel.applyChanges()
                }
                .frame(width: 294)
            }
        }
        .onDisappear {
            // Under the multi-select screen that screen clears the bar look itself.
            if onClose != nil { UINavigationBar.clearDarkBlueLook() }
        }
    }
    
    var bottomButtons: some View {
        HStack {
            Button {
                close(saved: false)
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

    private var confirmationMessage: String {
        let count = viewModel.selectedFiles.count
        return count > 1 ? String(format: "ChangeDateAndTimeOther".localized(), count) : "ChangeDateAndTimeOne".localized()
    }

    private func close(saved: Bool) {
        if let onClose {
            onClose(saved)
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension EditDateAndTimeView {
    /// The screen for one file, for UIKit to present. It closes itself, then tells `onClose` whether the date was saved.
    static func host(for file: FileModel, onClose: @escaping (Bool) -> Void) -> UIViewController {
        weak var host: UIViewController?
        let view = EditDateAndTimeView(viewModel: EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false)), onClose: { saved in
            host?.dismiss(animated: true) { onClose(saved) }
        })
        // The sheet's own bar reads the global look, as it does under the multi-select screen.
        UINavigationBar.applyDarkBlueLook()
        let controller = UIHostingController(rootView: view)
        host = controller
        return controller
    }
}

struct EditDateAndTimeView_Previews: PreviewProvider {
    @State static var hasUpdates: Bool = false
    static var previews: some View {
        EditDateAndTimeView(viewModel: EditDateAndTimeViewModel(selectedFiles: [], hasUpdates: $hasUpdates))
    }
}
