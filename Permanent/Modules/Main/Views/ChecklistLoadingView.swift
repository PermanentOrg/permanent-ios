//
//  ChecklistLoadingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2025.
import SwiftUI

struct ChecklistLoadingView: View {
    var body: some View {
        ZStack(alignment: .center)
        {
            GradientSemiCirclesLoaderView(innerCicleWidth: 7, innerCicleSize: 25, outerCicleWidth: 7)
                .frame(width: 48, height: 48, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
