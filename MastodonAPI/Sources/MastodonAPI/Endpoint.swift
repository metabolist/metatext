// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

public protocol Endpoint {
    associatedtype ResultType: Decodable
    var APIVersion: String { get }
    var context: [String] { get }
    var pathComponentsInContext: [String] { get }
    var method: HTTPMethod { get }
    var queryParameters: [String: String]? { get }
    var jsonBody: [String: Any]? { get }
    var headers: [String: String]? { get }
}

public extension Endpoint {
    var defaultContext: [String] {
        ["api", APIVersion]
    }

    var APIVersion: String { "v1" }

    var context: [String] {
        defaultContext
    }

    var pathComponents: [String] {
        context + pathComponentsInContext
    }

    var queryParameters: [String: String]? { nil }

    var jsonBody: [String: Any]? { nil }

    var headers: [String: String]? { nil }
}
