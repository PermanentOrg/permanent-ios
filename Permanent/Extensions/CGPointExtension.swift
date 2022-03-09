//
//  CGPointExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.03.2022.
//

import Foundation
import UIKit

extension CGPoint : Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
  }
}
