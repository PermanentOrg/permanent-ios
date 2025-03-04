//
//  CustomToggleView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.11.2024.

import SwiftUI

/// A SwiftUI view that represents a customizable toggle switch with configurable dimensions.
/// 
/// This view creates a toggle switch that:
/// - Can be customized with specific width and height
/// - Automatically scales to maintain proper proportions
/// - Includes smooth spring animation when toggled
/// - Wraps the toggle in a button for improved tap target size
/// 
/// The view is designed for use in settings, preferences, or any interface where
/// users need to toggle between two states. It maintains a consistent look while
/// allowing size customization to fit different design requirements.
/// 
/// - Parameters:
///   - isOn: Binding to a Boolean value that determines the toggle's state
///   - height: The height of the toggle (defaults to 20 points)
///   - width: The width of the toggle (defaults to 36 points)
///
/// # Example Usage
/// ```swift
/// // Basic usage with default size
/// CustomToggleView(isOn: $someToggleState)
///
/// // Custom sized toggle
/// CustomToggleView(
///     isOn: $someToggleState,
///     height: 24,
///     width: 44
/// )
/// ```
///
/// The view automatically handles proper scaling and touch target sizing
/// to ensure a good user experience regardless of the specified dimensions.

struct CustomToggleView: View {
    @Binding var isOn: Bool
    var height: CGFloat = 20
    var width: CGFloat = 36
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .frame(width: width, height: height)
                .scaleEffect(min(height / 31, width / 51))
                .animation(.spring(), value: isOn)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width + 20, height: height + 20, alignment: .top)
    }
}

struct CustomToggleView_Previews: PreviewProvider {
    static var previews: some View {
        CustomToggleView(isOn: .constant(true))
    }
} 
