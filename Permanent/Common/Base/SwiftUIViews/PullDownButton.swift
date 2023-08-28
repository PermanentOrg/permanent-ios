//
//  CustomDropdownView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 02.08.2023.

import SwiftUI

struct PullDownButton: View {
    
    @Binding var isSelecting: Bool
    @Binding var selectedItem: PullDownItem?
    let items: [PullDownItem]
    
    init(selectedItem: Binding<PullDownItem?>,
         items: [PullDownItem],
         isSelecting: Binding<Bool> = .constant(true)) {
        _selectedItem = selectedItem
        self.items = items
        _isSelecting = isSelecting
    }
    
    var body: some View {
        VStack {
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
                    Button(action: {
                        isSelecting = !isSelecting
                    }) {
                        HStack {
                            Text(selectedItem?.title ?? "Select Item")
                                .textStyle(SmallXXRegularTextStyle())
                                .animation(.none)
                            Spacer()
                            if items.count > 1 {
                                Image(systemName: "chevron.down")
                                    .rotationEffect(.degrees( isSelecting ? -180 : 0))
                            }
                            
                        }
                        .onTapGesture {
                            isSelecting.toggle()
                        }
                        .padding(.horizontal)
                    }
                    .buttonStyle(NoHighlightButtonStyle())
                    .disabled(items.count < 2)
                    .onTapGesture {
                        isSelecting.toggle()
                    }
                }
                
                if isSelecting && items.count > 1 {
                    VStack(spacing: 0) {
                        dropDownItemsList()
                    }
                    .background(Rectangle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: -2, y: 5))
                }
            }
            .padding(5)
        }
        .foregroundColor(Color.darkBlue)
        .frame(maxWidth: .infinity)
        .cornerRadius(5)
        .onAppear {
            selectedItem = items.first
        }
        .animation(.easeInOut(duration: 0.3))
    }
    
    private func dropDownItemsList() -> some View {
        ForEach(items) { item in
            PullDownItemView(isSelecting: $isSelecting, selectedItem: $selectedItem, item: item)
        }
    }
}

struct PullDownItem: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
}

struct PullDownItemView: View {
    @Binding var isSelecting: Bool
    @Binding var selectedItem: PullDownItem?
    
    let item: PullDownItem
    
    var body: some View {
        Button(action: {
            if selectedItem?.title == item.title {
                isSelecting.toggle()
            } else {
                selectedItem = item
                isSelecting = false
            }
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
    static var items = [
        PullDownItem(title: "Messages"),
        PullDownItem(title: "Archived"),
        PullDownItem(title: "Trash")
    ]
    
    @State static var selectedOption: PullDownItem?
    
    static var previews: some View {
        PullDownButton(selectedItem: $selectedOption, items: items)
        .padding()
    }
}

struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        // handle button role if necessary
        // if configuration.role == .destructive {
        //     configuration.label.foregroundColor(.red)
        // } else {
            configuration.label.foregroundColor(.black)
        // }
    }
}
