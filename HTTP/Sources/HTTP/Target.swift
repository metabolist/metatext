// Copyright © 2020 Metabolist. All rights reserved.

import Alamofire
import Foundation

public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias HTTPHeaders = Alamofire.HTTPHeaders
public typealias ParameterEncoding = Alamofire.ParameterEncoding
public typealias URLEncoding = Alamofire.URLEncoding
public typealias JSONEncoding = Alamofire.JSONEncoding

public protocol Target: URLRequestConvertible {
    var baseURL: URL { get }
    var pathComponents: [String] { get }
    var method: HTTPMethod { get }
    var encoding: ParameterEncoding { get }
    var parameters: [String: Any]? { get }
    var headers: HTTPHeaders? { get }
}

public extension Target {
    func asURLRequest() throws -> URLRequest {
        var url = baseURL

        for pathComponent in pathComponents {
            url.appendPathComponent(pathComponent)
        }

        return try encoding.encode(try URLRequest(url: url, method: method, headers: headers), with: parameters)
    }
}

public protocol DecodableTarget: Target {
    associatedtype ResultType: Decodable
}

public protocol TargetProcessing {
    static func process(target: Target)
}
