//
//  LegacyPlanningStatus.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 15.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import SwiftUI

struct LegacyPlanningStatus: View {
    var body: some View {
        ZStack {
            Color("PermDarkBlue").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    accountView
                    completedArchiveView
                    archiveView
                }
            }
            .padding(32)
        }
    }
    
    var accountView: some View {
        VStack {
            VStack(spacing: 24) {
                HStack {
                    Image("legacy_logo")
                        .frame(width: 48, height: 48)
                    Spacer()
                    Button {
                        
                    } label: {
                        HStack {
                            Text("Edit plan")
                                .textStyle(OpenSansXSmall())
                            Image(systemName: "square.and.pencil")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.16))
                
                Text("In the event of your death or incapacitation, the following Legacy contact can activate your Legacy Plan:")
                    .textStyle(OpenSansXSmall())
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                
                personView
                
                Divider()
                    .background(Color.white.opacity(0.16))
                
                Button {
                    
                } label: {
                    HStack {
                        Text("Turn off my account Legacy Plan")
                            .textStyle(OpenSansSemiBoldXSmall())
                        Spacer()
                        Image(systemName: "power")
                    }
                    .foregroundColor(Color("PermError"))
                }

            }
            .padding(24)
        }
        .background(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(.white.opacity(0.24), lineWidth: 1)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color("PermBlackBlue"))))
    }
    
    var personView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "person.fill")
                Text("Dorothy Zee")
                    .textStyle(OpenSansSemiBoldXSmall())
                Spacer()
            }
            .foregroundColor(.white)
        }
    }
    
    var archiveView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
            VStack(alignment: .leading, spacing: 24) {
                gradientBox
                    .frame(width: 35, height: 35)
                
                Text("The Sophia Petrillo Archive")
                    .textStyle(OpenSansSemiBoldRegular())
                    .foregroundColor(Color("PermDarkBlue"))
                
                Text("OWNER")
                    .textStyle(OpenSansTypography())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule()
                        .fill(Color("PermLavander")))
            
                Divider()
                
                Button {
                    
                } label: {
                    HStack {
                        Text("Create archive Legacy Plan")
                            .textStyle(OpenSansSemiBoldXSmall())
                            .foregroundColor(Color("PermDarkBlue"))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.black)
                }
            }
            .padding(24)
        }
    }
    
    var completedArchiveView: some View {
        VStack {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    gradientBox
                        .frame(width: 35, height: 35)
                    Spacer()
                    Button {
                        
                    } label: {
                        HStack {
                            Text("Edit plan")
                                .textStyle(OpenSansXSmall())
                            Image(systemName: "square.and.pencil")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.16))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Sophia Petrillo Archive")
                        .textStyle(OpenSansSemiBoldRegular())
                        .foregroundColor(.white)
                    
                    Text("OWNER")
                        .textStyle(OpenSansTypography())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule()
                            .fill(Color("PermLavander")))
                    
                    Text("Your archive Legacy Plan will be activated as follows:")
                        .textStyle(OpenSansXSmall())
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 10)  {
                    personView
                    
                    Text("Pending Invitation")
                        .foregroundColor(Color("PermWarning700"))
                        .textStyle(OpenSansTypography())
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule()
                            .fill(Color("PermWarning")))
                        .padding(.leading, 25)
                }
                
                Divider()
                    .background(Color.white.opacity(0.16))
                
                Button {
                    
                } label: {
                    HStack {
                        Text("Turn off this archive Legacy Plan")
                            .textStyle(OpenSansSemiBoldXSmall())
                        Spacer()
                        Image(systemName: "power")
                    }
                    .foregroundColor(Color("PermError"))
                }
            }
            .padding(24)
        }
        .background(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(.white.opacity(0.24), lineWidth: 1)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color("PermBlackBlue"))))
    }
    
    var gradientBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color("PermBarneyPurple"), Color("PermOrange")], startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack {
                VStack {
                    Divider()
                        .frame(height: 2)
                        .background(Color.white)
                    Text("SP")
                        .textStyle(OpenSansSemiBoldXXSmall())
                        .foregroundColor(.white)
                }
            }
            .padding(6)
            
        }
    }
}

struct LegacyPlanningStatus_Previews: PreviewProvider {
    static var previews: some View {
        LegacyPlanningStatus()
    }
}
