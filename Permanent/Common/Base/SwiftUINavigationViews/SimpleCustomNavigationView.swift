//
//  SimpleCustomNavigationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.12.2024.

import SwiftUI

struct SimpleCustomNavigationView<Content: View, LeftButton: View, RightButton: View>: View {
    @Environment(\.presentationMode) var presentationMode
    var content: Content
    var leftButtons: LeftButton?
    var rightButtons: RightButton?
    var backgroundColor: UIColor
    var textColor: UIColor
    var textStyle: TextStyle
    var showLeftChevron: Bool
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder leftButton: () -> LeftButton? = {nil}, @ViewBuilder rightButton: () -> RightButton? = {nil}, backgroundColor: UIColor = .darkBlue, textColor: UIColor = .white, textStyle: TextStyle = TextFontStyle.style50, showLeftChevron: Bool = true) {
        self.content = content()
        self.leftButtons = leftButton()
        self.rightButtons = rightButton()
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.textStyle = textStyle
        self.showLeftChevron = showLeftChevron
        
        UINavigationBar.appearance().backgroundColor = backgroundColor
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: textColor,
            NSAttributedString.Key.font: textStyle.font
        ]
        UINavigationBar.appearance().isTranslucent = false
        UIScrollView.appearance().bounces = false
        
        if #available(iOS 15, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor : textColor,
                NSAttributedString.Key.font: textStyle.font
            ]
            navigationBarAppearance.backgroundColor = backgroundColor
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            
            let tabBarApperance = UITabBarAppearance()
            tabBarApperance.configureWithOpaqueBackground()
            tabBarApperance.backgroundColor = backgroundColor
            UITabBar.appearance().scrollEdgeAppearance = tabBarApperance
            UITabBar.appearance().standardAppearance = tabBarApperance
        }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: backgroundColor)
            
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
                            if showLeftChevron {
                                Button(action: {
                                    self.presentationMode.wrappedValue.dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(Color(uiColor: textColor))
                                    }
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

extension SimpleCustomNavigationView where LeftButton == EmptyView, RightButton == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(content: content, leftButton: {
            EmptyView()
        }, rightButton: {
            EmptyView()
        })
    }
}
