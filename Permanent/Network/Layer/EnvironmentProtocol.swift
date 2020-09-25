//
//  EnvironmentProtocol.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

protocol EnvironmentProtocol {
    var headers: RequestHeaders? { get }
    var baseURL: String { get }
}
