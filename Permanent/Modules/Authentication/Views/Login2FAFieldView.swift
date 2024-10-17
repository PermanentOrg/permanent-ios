//
//  Login2FAFieldView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.09.2024.

import SwiftUI
import Combine


enum FocusPinType: Hashable {
    case pin(Int)
}

struct Login2FAFieldView: View {
    var numberOfFields: Int
    @Binding private var code: String
    @State private var pins: [String]
    @FocusState var pinFocusState: FocusPinType?
    @Binding var digitsDisabled: Bool

    init(numberOfFields: Int, code: Binding<String>, digitsDisabled: Binding<Bool>) {
        self.numberOfFields = numberOfFields
        self._code = code
        self._pins = State(initialValue: Array(repeating: "", count: numberOfFields))
        self._digitsDisabled = digitsDisabled
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<numberOfFields, id: \.self) { index in
                TextField("", text: $pins[index])
                    .modifier(CodeModifier(pin: $pins[index]))
                    .onChange(of: pins[index]) { newVal in
                        if newVal.count == 1 {
                            if index < numberOfFields - 1 {
                                pinFocusState = FocusPinType.pin(index + 1)
                            } else {
                                pinFocusState = nil
                            }
                        }
                        else if newVal.count == numberOfFields, let intValue = Int(newVal) {
                            code = newVal
                            updatePinsFromOTP()
                            pinFocusState = FocusPinType.pin(numberOfFields - 1)
                        }
                        else if newVal.isEmpty {
                            if index > 0 {
                                pinFocusState = FocusPinType.pin(index - 1)
                            }
                        }
                        updateOTPString()
                    }
                    .keyboardType(.numberPad)
                    .focused($pinFocusState, equals: FocusPinType.pin(index))
                    .disabled(digitsDisabled)
                    .onTapGesture {
                        pinFocusState = FocusPinType.pin(index)
                    }
            }
        }
        .onAppear {
            updatePinsFromOTP()
        }
    }
    
    private func updatePinsFromOTP() {
        let otpArray = Array(code.prefix(numberOfFields))
        for (index, char) in otpArray.enumerated() {
            pins[index] = String(char)
        }
    }
    
    private func updateOTPString() {
        code = pins.joined()
    }
}

struct CodeModifier: ViewModifier {
    @Binding var pin: String
    
    var textLimit = 1
    
    func limitText(_ upper: Int) {
        if pin.count > upper {
            self.pin = String(pin.prefix(upper))
        }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(height: 48)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .onReceive(Just(pin)) { _ in limitText(textLimit) }
            .font(.custom("Usual-Regular", size: 24))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
    }
}

struct Login2FAFieldView_Previews: PreviewProvider {
    static var previews: some View {
        
        ZStack {
            Gradient.darkLightBlueGradient
            Login2FAFieldView(numberOfFields: 4, code: .constant("4321"), digitsDisabled: .constant(false))
        }
        .ignoresSafeArea()
    }
}


