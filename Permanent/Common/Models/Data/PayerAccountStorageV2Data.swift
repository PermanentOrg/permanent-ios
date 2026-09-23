//
//  PayerAccountStorageV2Data.swift
//  Permanent
//

import Foundation

/// Storage on the account that pays for an archive. Stela returns a bare object with every field
/// quoted, so only the one figure the upload gate needs is decoded.
struct PayerAccountStorageV2Data: Model {
    let spaceLeft: String?

    /// The payer's headroom in bytes. Negative means the payer is already over quota.
    var spaceLeftBytes: Int? { spaceLeft.flatMap(Int.init) }
}
