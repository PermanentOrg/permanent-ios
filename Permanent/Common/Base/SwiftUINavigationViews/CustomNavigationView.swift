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
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white,
            NSAttributedString.Key.font: TextFontStyle.style51.font
        ]
        UINavigationBar.appearance().isTranslucent = false
        
        if #available(iOS 15, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor : UIColor.white,
                NSAttributedString.Key.font: TextFontStyle.style51.font
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
        }
        .onAppear {
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
            #if !canImport(ShareExtension)
            AppDelegate.orientationLock = .portrait
            ScrollViewAppearanceManager.shared.pushScrollViewBounce(enabled: false, identifier: "CustomNavigationView")
            #endif
        }
        .onDisappear {
            if #available(iOS 26.0, *) {
                // On iOS 26, the global UINavigationBar.appearance() proxy set in our init
                // bleeds into SwiftUI NavigationStack views (e.g. the Settings sheet) because
                // toolbarBackground no longer overrides the proxy per-instance. Fully clear
                // the proxy to transparent when this view disappears so any subsequently
                // opened NavigationStack gets a clean, transparent nav bar.
                // UIKit screens (Legacy Planning, main file browser) set isTranslucent = false
                // explicitly in styleNavBar() / NavigationController.viewDidLoad, so they are
                // not affected by resetting it to true here.
                let transparent = UINavigationBarAppearance()
                transparent.configureWithTransparentBackground()
                UINavigationBar.appearance().standardAppearance = transparent
                UINavigationBar.appearance().compactAppearance = transparent
                UINavigationBar.appearance().scrollEdgeAppearance = transparent
                UINavigationBar.appearance().backgroundColor = nil
                UINavigationBar.appearance().isTranslucent = true
            }
            #if !canImport(ShareExtension)
            AppDelegate.orientationLock = .all
            ScrollViewAppearanceManager.shared.popScrollViewBounce(identifier: "CustomNavigationView")
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
