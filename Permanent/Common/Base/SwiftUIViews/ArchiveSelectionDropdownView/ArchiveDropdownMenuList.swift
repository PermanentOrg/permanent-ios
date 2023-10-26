//
//  ArchiveDropdownMenuList.swift
//  DropdownMenu
//

import SwiftUI

struct ArchiveDropdownMenuList: View {
    /// The drop-down menu list options
    let options: [ArchiveDropdownMenuOption]
    
    /// An action called when user select an action.
    let onSelectedAction: (_ option: ArchiveDropdownMenuOption) -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                ForEach(options) { option in
                    ArchiveDropdownMenuListRow(option: option, onSelectedAction: self.onSelectedAction)
                }
            }
        }
        // Check first if number of options * 88 (Option height - CONSTANT - YOU
        // MAY CHANGE IT) is greater than 500 (MAX HEIGHT - ALSO, YOU MAY CHANGE
        // IT), if true, then make it options list scroll, if not set frame only
        // for available options.
        .frame(height: CGFloat(self.options.count * 88) > 500
               ? 500
               : CGFloat(self.options.count * 88)
        )
    }
}

struct ArchiveDropdownMenuList_Previews: PreviewProvider {
    static var previews: some View {
        ArchiveDropdownMenuList(options: [ArchiveDropdownMenuOption.testSingleArchive], onSelectedAction: { _ in })
    }
}
