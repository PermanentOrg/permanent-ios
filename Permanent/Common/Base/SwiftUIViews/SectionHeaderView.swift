//
//  SectionHeaderView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.07.2023.

import SwiftUI
import SDWebImageSwiftUI

struct SectionHeaderView<ViewModel: GenericViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            HStack {
                if let viewModel = viewModel as? FilesMetadataViewModel {
                    let files = viewModel.selectedFiles
                    if !files.isEmpty, let url = URL(string: files.first?.thumbnailURL500) {
                        WebImage(url: url)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .aspectRatio(contentMode: .fill)
                    }
                    Text("Editing \(Int(files.count)) items")
                        .textStyle(SmallBoldTextStyle())
                }
                Spacer()
            }
        }
        .padding(.top, 24)
    }
}

struct SectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeaderView(viewModel: FilesMetadataViewModel(files: []))
    }
}
