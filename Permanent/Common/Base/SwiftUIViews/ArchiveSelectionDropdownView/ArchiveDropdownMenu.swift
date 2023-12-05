//
//  ArchiveDropdownMenu.swift
//  DropdownMenu
//

import SwiftUI
import SDWebImageSwiftUI

struct ArchiveDropdownMenu: View {
	/// Used to show or hide drop-down menu options
    @Binding var isOptionsPresented: Bool
	
	/// Used to bind user selection
	@Binding var selectedOption: ArchiveDropdownMenuOption
	
	/// A placeholder for drop-down menu
	let placeholder: String
	
	/// The drop-down menu options
	let options: [ArchiveDropdownMenuOption]
    
    /// An action called when user select an action.
    let onSelectedAction: (_ option: ArchiveDropdownMenuOption) -> Void
	
    var body: some View {
        if #available(iOS 15.0, *) {
            Button(action: {
                withAnimation {
                    self.isOptionsPresented.toggle()
                }
            }) {
                ZStack {
                    if !isOptionsPresented {
                        Rectangle()
                            .foregroundColor(.clear)
                            .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                            .frame(height: 88)
                            .padding(.horizontal, -30)
                            .padding(.top, 0)
                    }
                    HStack(spacing: 16) {
                        if !isOptionsPresented {
                            WebImage(url: URL(string: selectedOption.archiveThumbnailAddress))
                                .resizable()
                                .placeholder(content: {
                                    VStack {
                                        Image("questionMark")
                                    }
                                })
                                .frame(width: 40, height: 40)
                                .aspectRatio(contentMode: .fill)
                                .cornerRadius(6.0)
                            Text(selectedOption.archiveName.isEmpty ? placeholder : selectedOption.archiveName)
                                .textStyle(SmallSemiBoldTextStyle())
                                .foregroundColor(selectedOption.archiveName.isEmpty ? .gray : .black)
                        } else {
                            Text("Select archive ...")
                                .textStyle(SmallRegularTextStyle())
                                .foregroundColor(.middleGray)
                        }
                        Spacer()
                        Image(systemName: self.isOptionsPresented ? "chevron.up" : "chevron.down")
                            .foregroundColor(.black)
                    }
                    .frame(height: 88)
                    .padding(.horizontal, 24)
                }
            }
            .overlay(alignment: .top) {
                VStack {
                    if self.isOptionsPresented {
                        Spacer(minLength: 88)
                        ArchiveDropdownMenuList(options: self.options, onSelectedAction: self.onSelectedAction)
                    }
                }
            }
            // We need to push views under drop down menu down, when options list is
            // open
            .padding(
                // Check if options list is open or not
                .bottom, self.isOptionsPresented
                // If options list is open, then check if options size is greater
                // than 500 (MAX HEIGHT - CONSTANT), or not
                ? CGFloat(self.options.count * 88) > 500
                // IF true, then set padding to max height 500 points
                ? 500 // max height + more padding to set space between borders and text
                // IF false, then calculate options size and set padding
                : CGFloat(self.options.count * 88)
                // If option list is closed, then don't set any padding.
                : 0
            )
        } else {
            Button(action: {
                withAnimation {
                    self.isOptionsPresented.toggle()
                }
            }) {
                ZStack {
                    if !isOptionsPresented {
                        Rectangle()
                            .foregroundColor(.clear)
                            .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                            .frame(height: 88)
                            .padding(.horizontal, -30)
                            .padding(.top, 0)
                    }
                    HStack(spacing: 16) {
                        if !isOptionsPresented {
                            WebImage(url: URL(string: selectedOption.archiveThumbnailAddress))
                                .resizable()
                                .placeholder(content: {
                                    VStack {
                                        Image("questionMark")
                                    }
                                })
                                .frame(width: 40, height: 40)
                                .aspectRatio(contentMode: .fill)
                                .cornerRadius(6.0)
                            Text(selectedOption.archiveName.isEmpty ? placeholder : selectedOption.archiveName)
                                .textStyle(SmallSemiBoldTextStyle())
                                .foregroundColor(selectedOption.archiveName.isEmpty ? .gray : .black)
                        } else {
                            Text("Select archive ...")
                                .textStyle(SmallRegularTextStyle())
                                .foregroundColor(.middleGray)
                        }
                        Spacer()
                        Image(systemName: self.isOptionsPresented ? "chevron.up" : "chevron.down")
                            .foregroundColor(.black)
                    }
                    .frame(height: 88)
                    .padding(.horizontal, 24)
                }
            }
            VStack {
                if self.isOptionsPresented {
                    Spacer(minLength: 88)
                    ArchiveDropdownMenuList(options: self.options, onSelectedAction: self.onSelectedAction)
                }
            }
            
            // We need to push views under drop down menu down, when options list is
            // open
            .padding(
                // Check if options list is open or not
                .bottom, self.isOptionsPresented
                // If options list is open, then check if options size is greater
                // than 500 (MAX HEIGHT - CONSTANT), or not
                ? CGFloat(self.options.count * 88) > 500
                // IF true, then set padding to max height 500 points
                ? 500 // max height + more padding to set space between borders and text
                // IF false, then calculate options size and set padding
                : CGFloat(self.options.count * 88)
                // If option list is closed, then don't set any padding.
                : 0
            )
        }
    }
}

struct ArchiveDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        ArchiveDropdownMenu(
            isOptionsPresented: .constant(false),
            selectedOption: .constant(ArchiveDropdownMenuOption(archiveName: "", archiveThumbnailAddress: "", archiveAccessRole: "",archiveNbr: "", isArchiveSelected: false)),
			placeholder: "Select your archive",
            options: [ArchiveDropdownMenuOption.testSingleArchive], onSelectedAction: { _ in }
		)
    }
}
