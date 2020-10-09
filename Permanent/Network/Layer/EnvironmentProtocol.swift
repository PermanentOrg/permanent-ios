//
//  EnvironmentProtocol.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

protocol EnvironmentProtocol {
    var headers: RequestHeaders? { get }
    var baseURL: String { get }
}
