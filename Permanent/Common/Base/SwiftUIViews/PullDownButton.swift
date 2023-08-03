//
//  CustomDropdownView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 02.08.2023.

import SwiftUI

struct Option: Identifiable, Hashable {
    let id = UUID()
    let title: String
}

struct PullDownButton: View {
    
    @State var isSelecting = false
    @State var selectionTitle = ""
    @State var selectedRowId = 0
    let items: [PullDownItem]
    
    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .foregroundColor(.clear)
                        .frame(height: 48)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.99).opacity(0.5))
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.96, green: 0.96, blue: 0.99), lineWidth: 1)
                        )
                    HStack {
                        Text(selectionTitle)
                            .textStyle(SmallXXRegularTextStyle())
                            .animation(.none)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees( isSelecting ? -180 : 0))
                        
                    }
                    .padding(.horizontal)
                }
                
                if isSelecting {
                    VStack(spacing: 0) {
                        dropDownItemsList()
                    }
                    .background(Rectangle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: -3, y: 2))
                }
            }
            .foregroundColor(Color.darkBlue)
            .frame(maxWidth: .infinity)
            .cornerRadius(5)
            .onTapGesture {
                isSelecting.toggle()
            }
            .onAppear {
                selectedRowId = items[0].id
                selectionTitle = items[0].title
            }
            .animation(.easeInOut(duration: 0.3))
        }
    }
    
    private func dropDownItemsList() -> some View {
        ForEach(items) { item in
            PullDownItemView(isSelecting: $isSelecting, selectionId: $selectedRowId, selectiontitle: $selectionTitle, item: item)
        }
    }
}

struct PullDownItem: Identifiable {
    let id: Int
    let title: String
    let onSelect: (() -> Void)?
}

struct PullDownItemView: View {
    @Binding var isSelecting: Bool
    @Binding var selectionId: Int
    @Binding var selectiontitle: String
    
    let item: PullDownItem
    
    var body: some View {
        Button(action: {
            isSelecting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                selectionId = item.id
            }
            selectiontitle = item.title
            item.onSelect?()
        }) {
            HStack {
                Text(item.title)
                    .textStyle(SmallXXRegularTextStyle())
                Spacer()
            }
            .frame(height: 48)
            .padding(.horizontal)
        }
    }
}

struct CustomDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        PullDownButton(items: [
            PullDownItem(id: 1, title: "Messages", onSelect: {}),
            PullDownItem(id: 2, title: "Archived", onSelect: {}),
            PullDownItem(id: 3, title: "Trash", onSelect: {})
        ])
        .padding()
    }
}
