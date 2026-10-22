//
//  ViewExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.11.2023.
//

import SwiftUI
import Combine

extension View {
    /// The dark-blue bar of a metadata sheet: a white title, and a white X at the top right that closes it.
    /// The dark scheme keeps the X's iOS 26 glass dark on the blue, as the app's other bars are.
    func darkBarSheet(title: String, onClose: @escaping () -> Void) -> some View {
        navigationBarTitle(title, displayMode: .inline)
            .toolbarBackground(Color.darkBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Close".localized())
                }
            }
    }
}

extension View {
    var keyboardPublisher: AnyPublisher<(isFirstResponder: Bool, aView: any View), Never> {
    Publishers
      .Merge(
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillShowNotification)
          .map { _ in (true, self) },
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillHideNotification)
          .map { _ in (false, self) })
      .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
      .eraseToAnyPublisher()
  }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
