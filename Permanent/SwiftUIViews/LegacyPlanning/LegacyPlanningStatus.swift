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
                    archiveView
                    accountView
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
                    HStack {
                        Text("Edit plan")
                        Image(systemName: "square.and.pencil")
                    }
                    .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.16))
                
                Text("In the event of your death or incapacitation, the following Legacy contact can activate your Legacy Plan:")
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                
                accountDetailsView
                
                Divider()
                    .background(Color.white.opacity(0.16))
                
                Button {
                    
                } label: {
                    HStack {
                        Text("Turn off my account Legacy Plan")
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
    
    var accountDetailsView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "person.fill")
                Text("by Dorothy Zee")
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
                    .frame(width: 40, height: 40)
                
                Text("The Sophia Petrillo Archive")
                
 
                Text("OWNER")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule()
                        .fill(Color("PermBarneyPurple").opacity(0.2)))
            
                Divider()
                
                Button {
                    
                } label: {
                    HStack {
                        Text("Create archive Legacy Plan")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.black)
                }
            }
            .padding(24)
        }
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
