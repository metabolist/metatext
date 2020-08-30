// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Alamofire

public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias HTTPHeaders = Alamofire.HTTPHeaders
public typealias ParameterEncoding = Alamofire.ParameterEncoding
public typealias URLEncoding = Alamofire.URLEncoding
public typealias JSONEncoding = Alamofire.JSONEncoding

public protocol HTTPTarget: URLRequestConvertible {
    var baseURL: URL { get }
    var pathComponents: [String] { get }
    var method: HTTPMethod { get }
    var encoding: ParameterEncoding { get }
    var parameters: [String: Any]? { get }
    var headers: HTTPHeaders? { get }
}

public extension HTTPTarget {
    func asURLRequest() throws -> URLRequest {
        var url = baseURL

        for pathComponent in pathComponents {
            url.appendPathComponent(pathComponent)
        }

        return try encoding.encode(try URLRequest(url: url, method: method, headers: headers), with: parameters)
    }
}

public protocol DecodableTarget: HTTPTarget {
    associatedtype ResultType: Decodable
}
