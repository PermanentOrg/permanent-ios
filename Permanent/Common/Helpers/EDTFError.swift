//
//  EDTFError.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation

/// Carries the message the JavaScript layer produced, so the screen can show why a value was refused.
enum EDTFError: Error, Equatable {
    /// The parts or the string were not valid EDTF. The string is the bridge's own wording.
    case rejected(String)
    /// The JavaScript context could not be created or the bundle did not evaluate.
    case unavailable
}
