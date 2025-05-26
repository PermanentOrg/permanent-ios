//
//  ChecklistOptionsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2025.
import SwiftUI
import UIKit

struct ChecklistOptionsView: View {
    @StateObject private var viewModel: ChecklistOptionsViewModel
    let onDisableChecklist: () -> Void
    
    init(items: [ChecklistItem], completionPercentage: Int, showsChecklistButton: Bool, onDisableChecklist: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ChecklistOptionsViewModel(items: items, completionPercentage: completionPercentage, showsChecklistButton: showsChecklistButton))
        self.onDisableChecklist = onDisableChecklist
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Account set up")
                    .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                    .font(.custom("Usual-Regular", size: 12))
                    .fontWeight(.regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(viewModel.completionPercentage)%")
                    .foregroundColor(.black)
                    .font(.custom("Usual-Regular", size: 12))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            ProgressView(value: Float(viewModel.completionPercentage) / 100)
                .progressViewStyle(CustomBarProgressGradientStyle(colorScheme: .solidGreenWithWhiteBar, height: 8, cornerRadius: 3))
                .frame(height: 8)
                .id(viewModel.redraw)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(viewModel.items, id: \.id) { item in
                    Button {
                        viewModel.handleItemTap(item)
                    } label: {
                        ChecklistItemView(item: item)
                    }
                    .disabled(item.completed || item.type == .archiveCreated)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .padding(.bottom, 80)
        }
        .onAppear {
            UIScrollView.appearance().bounces = false
        }
        .onDisappear {
            UIScrollView.appearance().bounces = true
        }
        if viewModel.showsChecklistButton {
            VStack(spacing: 0) {
                Divider()
                    .background(Color(red: 0.89, green: 0.89, blue: 0.93))
                    .padding(.horizontal, 0)
                HStack(spacing: 24) {
                    Image(.memberchecklistDontShowAgain)
                        .renderingMode(.template)
                        .frame(width: 24, height: 24, alignment: .center)
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                    
                    Text("Don't show me this again")
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                        .font(.custom("Usual-Regular", size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(height: 80)
                .background(Color.white)
                .onTapGesture {
                    withAnimation {
                        onDisableChecklist()
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}

struct ChecklistItemView: View {
    let item: ChecklistItem
    
    var body: some View {
        HStack(spacing: 24) {
            if let imageName = item.imageName {
                Image(imageName)
                    .renderingMode(.template)
                    .frame(width: 24, height: 24, alignment: .center)
                    .foregroundColor(item.completed ? Color(red: 0.54, green: 0.55, blue: 0.64) : Color(red: 0.07, green: 0.11, blue: 0.29))
            }
            if let type = item.type {
                Text(item.title)
                    .strikethrough(item.completed || type == ChecklistItemType.archiveCreated)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(item.completed ? Color(red: 0.54, green: 0.55, blue: 0.64) : Color(red: 0.07, green: 0.11, blue: 0.29))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Image(item.completed ? .memberchecklistCheckedSign : .memberchecklistRightArrow)
                .frame(width: 24, height: 24, alignment: .center)
        }
    }
}
