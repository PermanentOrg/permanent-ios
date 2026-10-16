//
//  JavaScriptCoreEDTF.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation
import JavaScriptCore

/// Runs Web's edtf.js inside JavaScriptCore, so an archived string is byte-identical to the one Web
/// would write. A `JSContext` is not thread-safe, so every call is confined to one serial queue.
final class JavaScriptCoreEDTF: EDTFFormatting, @unchecked Sendable {
    static let shared = JavaScriptCoreEDTF()

    private let queue = DispatchQueue(label: "org.permanent.edtf")
    private var loadedContext: JSContext?
    private var didAttemptLoad = false

    // MARK: - EDTFFormatting

    func string(from parts: EDTFDateParts) throws -> String {
        try emitted(from: try call("format", body(parts)))
    }

    func string(from interval: EDTFInterval) throws -> String {
        try emitted(from: try call("format", body(interval)))
    }

    func validated(_ text: String) throws -> String {
        try emitted(from: try call("validate", text))
    }

    func value(from text: String) throws -> EDTFValue {
        let payload = try call("decompose", text)
        guard let parts = payload["parts"] else { throw EDTFError.rejected(reason(payload)) }
        let data = try JSONSerialization.data(withJSONObject: parts)
        if let interval = try? JSONDecoder().decode(EDTFInterval.self, from: data) {
            return .interval(interval)
        }
        return .date(try JSONDecoder().decode(EDTFDateParts.self, from: data))
    }

    // MARK: - Bridge

    /// The bundle exports one global. Both directions are strings, so no `JSValue` escapes this file.
    private func call(_ function: String, _ argument: String) throws -> [String: Any] {
        try queue.sync {
            guard let context = context(),
                  let api = context.objectForKeyedSubscript("PermanentEDTF"),
                  let method = api.objectForKeyedSubscript(function),
                  !method.isUndefined else {
                throw EDTFError.unavailable
            }
            guard let text = method.call(withArguments: [argument])?.toString(),
                  let data = text.data(using: .utf8),
                  let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw EDTFError.unavailable
            }
            return payload
        }
    }

    /// Built on first use and kept. Evaluating the bundle costs a few milliseconds, so it is not per-call.
    private func context() -> JSContext? {
        if didAttemptLoad { return loadedContext }
        didAttemptLoad = true
        guard let context = JSContext() else { return nil }
        context.evaluateScript(EDTFBundleSource.javaScript)
        guard context.exception == nil else { return nil }
        loadedContext = context
        return context
    }

    private func emitted(from payload: [String: Any]) throws -> String {
        guard payload["ok"] as? Bool == true, let text = payload["edtf"] as? String else {
            throw EDTFError.rejected(reason(payload))
        }
        return text
    }

    private func reason(_ payload: [String: Any]) -> String {
        payload["error"] as? String ?? "not a valid EDTF value"
    }

    private func body<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let text = String(bytes: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
