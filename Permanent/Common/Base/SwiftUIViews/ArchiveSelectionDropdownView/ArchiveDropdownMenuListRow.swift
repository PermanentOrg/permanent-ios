//
//  DropdownMenuListRow.swift
//  DropdownMenu
//

import SwiftUI
import SDWebImageSwiftUI

struct ArchiveDropdownMenuListRow: View {
    let option: ArchiveDropdownMenuOption
    
    /// An action called when user select an action.
    let onSelectedAction: (_ option: ArchiveDropdownMenuOption) -> Void
    
    var body: some View {
        Button(action: {
            if !option.archiveAccessRole.lowercased().contains("viewer") {
                self.onSelectedAction(option)
            }})
        {
            ZStack {
                if option.isArchiveSelected {
                    Rectangle()
                        .foregroundColor(.clear)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                        .frame(height: 88)
                        .padding(.horizontal, -30)
                        .padding(.top, 0)
                }
                HStack(spacing: 16) {
                    WebImage(url: URL(string: option.archiveThumbnailAddress))
                        .resizable()
                        .placeholder(content: {
                            VStack {
                                Image("questionMark")
                            }
                        })
                        .frame(width: 40, height: 40)
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(6.0)
                        .saturation(option.archiveAccessRole.lowercased().contains("viewer") ? 0 : 1)
                        .opacity(option.archiveAccessRole.lowercased().contains("viewer") ? 0.3 : 1)
                    Text(option.archiveName)
                        .textStyle(SmallSemiBoldTextStyle())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                        .saturation(option.archiveAccessRole.lowercased().contains("viewer") ? 0 : 1)
                        .opacity(option.archiveAccessRole.lowercased().contains("viewer") ? 0.3 : 1)
                    Spacer()
                    if #available(iOS 16.0, *) {
                        Text(option.archiveAccessRole.uppercased())
                            .textStyle(SmallXXXXXXRegularTextStyle())
                            .kerning(0.8)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundColor(.darkBlue)
                            .background(Rectangle()
                                .fill(option.archiveAccessRole.lowercased().contains("owner") ?
                                      Color(red: 0.91, green: 0.8, blue: 0.91).opacity(0.7) :
                                        .tangerine.opacity(0.2))
                                    .clipShape(.rect(cornerRadius: 4.0))
                            )
                    } else {
                        Text(option.archiveAccessRole.uppercased())
                            .textStyle(SmallXXXXXXRegularTextStyle())
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundColor(.darkBlue)
                            .background(Rectangle()
                                .fill(option.archiveAccessRole.lowercased().contains("owner") ?
                                      Color(red: 0.91, green: 0.8, blue: 0.91).opacity(0.7) :
                                        .tangerine.opacity(0.2))
                                    .clipShape(.rect(cornerRadius: 4.0))
                            )
                    }
                }
                .frame(height: 88)
                .padding(.horizontal, 24)
            }
        }
        .disabled(option.archiveAccessRole.lowercased().contains("viewer"))
        .foregroundColor(.black)
    }
}

struct ArchiveDropdownMenuListRow_Previews: PreviewProvider {
    static var previews: some View {
        ArchiveDropdownMenuListRow(option: ArchiveDropdownMenuOption.testSingleArchive, onSelectedAction: { _ in })
    }
}
