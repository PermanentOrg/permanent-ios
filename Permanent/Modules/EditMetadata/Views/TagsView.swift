//
//  TagsView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

struct TagsView: View {
    @State var words = [
        "Family","Kids","Grill","Outdoor","Mountains","Cabin", "NewTag"
    ]
    
    var body: some View {
        ScrollView {
            FlowGrid(
                data: words,
                spacing: 8,
                alignment: .leading) { item in
                VStack {
                    if item == "NewTag" {
                        addtagView()
                    } else {
                        tagView(text: item)
                    }
                }
            }
        }
    }
    
    func tagView(text: String) -> some View {
        VStack {
            HStack {
                Text(text)
                    .textStyle(SmallXXRegularTextStyle())
                Button {
                    words.removeAll { $0 == text }
                } label: {
                    Image("xMarkToolbarIcon")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
        }
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.indianSaffron.opacity(0.2)))
        .foregroundColor(Color.darkBlue)
    }
    
    func addtagView() -> some View {
        VStack {
            HStack {
                Button {
                    words.insert("Item", at: words.count - 1)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("New tag")
                            .textStyle(SmallXXRegularTextStyle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
        }
        .background(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.darkBlue.opacity(0.1), lineWidth: 1))
        .foregroundColor(Color.darkBlue)
    }
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
    }
}
