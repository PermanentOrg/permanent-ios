//
//  CustomNavigationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.06.2023.

import SwiftUI

struct CustomNavigationView<Content: View>: View {
    @Environment(\.presentationMode) var presentationMode
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        UINavigationBar.appearance().backgroundColor = .darkBlue
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().isTranslucent = false
        UIScrollView.appearance().bounces = false
        
        if #available(iOS 15, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor : UIColor.white
            ]
            navigationBarAppearance.backgroundColor = UIColor.darkBlue
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            
            let tabBarApperance = UITabBarAppearance()
            tabBarApperance.configureWithOpaqueBackground()
            tabBarApperance.backgroundColor = UIColor.darkBlue
            UITabBar.appearance().scrollEdgeAppearance = tabBarApperance
            UITabBar.appearance().standardAppearance = tabBarApperance
        }
    }
    
    var body: some View {
        ZStack {
            Color.darkBlue
            
            NavigationView {
                VStack {
                    GeometryReader { geometry in
                        content
                            .padding(.bottom, -geometry.safeAreaInsets.bottom)
                    }
                }
                .padding(.horizontal, 0)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct CustomNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavigationView {
            HStack {
                Spacer()
                List {
                    VStack {
                        Spacer()
                        Text("Hello world")
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}
