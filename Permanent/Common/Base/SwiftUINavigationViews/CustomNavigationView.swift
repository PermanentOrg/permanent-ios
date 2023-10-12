//
//  CustomNavigationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.06.2023.

import SwiftUI

struct CustomNavigationView<Content: View, LeftButton: View, RightButton: View>: View {
    @Environment(\.presentationMode) var presentationMode
    var content: Content
    var leftButtons: LeftButton?
    var rightButtons: RightButton?
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder leftButton: () -> LeftButton? = {nil}, @ViewBuilder rightButton: () -> RightButton? = {nil}) {
        self.content = content()
        self.leftButtons = leftButton()
        self.rightButtons = rightButton()
        
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
                        if (leftButtons is EmptyView) {
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                }
                            }
                        } else {
                            leftButtons
                        }

                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if !(rightButtons is EmptyView) {
                            rightButtons
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
        }.onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            #if !canImport(ShareExtension)
            AppDelegate.orientationLock = .portrait
            #endif
        }.onDisappear {
            #if !canImport(ShareExtension)
            AppDelegate.orientationLock = .all
            #endif
        }
        .edgesIgnoringSafeArea(.all)
    }
}

extension CustomNavigationView where LeftButton == EmptyView, RightButton == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(content: content, leftButton: {
            EmptyView()
        }, rightButton: {
            EmptyView()
        })
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
