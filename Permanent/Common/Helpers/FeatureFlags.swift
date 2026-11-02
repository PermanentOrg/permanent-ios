//
//  FeatureFlags.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation

/// The server's switches: a name the flag list carries is on, every other name is off. The list is fetched once
/// at launch and kept, so a cold start reads as the last run did until the new answer lands.
final class FeatureFlags {
    static let shared = FeatureFlags()

    /// On, the screens show `displayTime` only and leave the old date field out, as web does.
    static let edtfDateName = "edtf-date"

    /// The fetch, replaceable by a test: it answers with the names that are on, or an error.
    var listRequest: (@escaping (Result<[String], Error>) -> Void) -> Void = FeatureFlags.fetchFromServer

    private(set) var enabledNames: Set<String>
    private let defaults: UserDefaults
    private static let savedNamesKey = "featureFlagNames"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabledNames = Set(defaults.stringArray(forKey: Self.savedNamesKey) ?? [])
    }

    var showsOnlyEDTFDate: Bool {
        isEnabled(Self.edtfDateName)
    }

    func isEnabled(_ name: String) -> Bool {
        enabledNames.contains(name)
    }

    /// Asks the server once and keeps the answer; an error keeps the last answer. The completion runs on main.
    func refresh(completion: ((Bool) -> Void)? = nil) {
        listRequest { [weak self] result in
            DispatchQueue.main.async {
                guard let self, case .success(let names) = result else {
                    completion?(false)
                    return
                }
                self.apply(names: names)
                completion?(true)
            }
        }
    }

    /// Replaces the switches that are on and saves them for the next launch.
    func apply(names: [String]) {
        enabledNames = Set(names)
        defaults.set(Array(enabledNames).sorted(), forKey: Self.savedNamesKey)
    }

    private static func fetchFromServer(completion: @escaping (Result<[String], Error>) -> Void) {
        let operation = APIOperation(FeatureFlagsV2Endpoint.list)
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                let items = (json as? [String: Any])?["items"] as? [[String: Any]] ?? []
                completion(.success(items.compactMap { $0["name"] as? String }))

            case .error(let error, _):
                completion(.failure(error ?? APIError.unknown))

            default:
                completion(.failure(APIError.invalidResponse))
            }
        }
    }
}
