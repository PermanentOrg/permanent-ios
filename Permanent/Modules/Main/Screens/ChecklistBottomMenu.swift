//
//  ChecklistBottomMenu.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.05.2025.


import SwiftUI
import UIKit

struct ChecklistBottomMenu: View {
    @Environment(\.presentationMode) var presentationMode
    let items: [ChecklistItem] = [
        ChecklistItem(type: .archiveCreated, completed: true),
        ChecklistItem(type: .storageRedeemed, completed: true),
        ChecklistItem(type: .firstUpload, completed: true),
        ChecklistItem(type: .archiveSteward, completed: false),
        ChecklistItem(type: .legacyContact, completed: false),
        ChecklistItem(type: .archiveProfile, completed: false),
        ChecklistItem(type: .publishContent, completed: false)
    ]
    
    private var completionPercentage: Int {
        let completedCount = items.filter { $0.completed }.count
        return Int((Double(completedCount) / Double(items.count)) * 100)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 16) {
                            HStack(alignment: .center, spacing: 0) {
                                Image(.memberChecklistTitleLogo)
                                .frame(width: 24, height: 24)
                            }
                            .frame(width:40, height: 40, alignment: .center)
                            .background(.white)
                            .cornerRadius(40)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Getting started")
                                    .font(.custom("Usual-Regular", size: 14)
                                    .weight(.medium)
                                    )
                                .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                                Text("Let's finish setting up your account")
                                  .font(.custom("Usual-Regular", size: 12))
                                  .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(.memberchecklistMinus)
                                    .frame(width: 24, height: 24, alignment: .center)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 88)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Account set up")
                                .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                                .font(.custom("Usual-Regular", size: 12))
                                .fontWeight(.regular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(completionPercentage)%")
                                .foregroundColor(.black)
                                .font(.custom("Usual-Regular", size: 12))
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(items, id: \.id) { item in
                                ChecklistItemView(item: item)
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
                }
            }
            
            // Bottom Section
            VStack(spacing: 0) {
                Divider()
                    .background(Color(red: 0.89, green: 0.89, blue: 0.93))
                    .padding(.horizontal, 0)
                HStack(spacing: 24) {
                    Image(.memberchecklistDontShowAgain)
                        .renderingMode(.template)
                        .frame(width: 24, height: 24, alignment: .center)
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                    
                    Text("Don’t show me this again")
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                        .font(.custom("Usual-Regular", size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(height: 80)
                .background(Color.white)
            }
            .padding(.bottom, 10)
        }
        .background(Color.white)
    }
}

struct ChecklistItemView: View {
    let item: ChecklistItem
    
    var body: some View {
        HStack(spacing: 24) {
            Image(item.imageName)
                .renderingMode(.template)
                .frame(width: 24, height: 24, alignment: .center)
                .foregroundColor(item.completed ? Color(red: 0.54, green: 0.55, blue: 0.64) : Color(red: 0.07, green: 0.11, blue: 0.29))
            
            Text(item.title)
                .strikethrough(item.completed)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(item.completed ? Color(red: 0.54, green: 0.55, blue: 0.64) : Color(red: 0.07, green: 0.11, blue: 0.29))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(item.completed ? .memberchecklistCheckedSign : .memberchecklistRightArrow)
                .frame(width: 24, height: 24, alignment: .center)
        }
    }
}

struct ChecklistBottomMenu_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistBottomMenu()
    }
}
