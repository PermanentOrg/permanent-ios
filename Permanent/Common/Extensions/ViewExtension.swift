//
//  ViewExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.11.2023.

import SwiftUI
import Combine

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
