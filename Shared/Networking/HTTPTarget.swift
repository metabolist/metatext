// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Alamofire

typealias HTTPMethod = Alamofire.HTTPMethod
typealias HTTPHeaders = Alamofire.HTTPHeaders
typealias ParameterEncoding = Alamofire.ParameterEncoding
typealias URLEncoding = Alamofire.URLEncoding
typealias JSONEncoding = Alamofire.JSONEncoding

protocol HTTPTarget: URLRequestConvertible {
    var baseURL: URL { get }
    var pathComponents: [String] { get }
    var method: HTTPMethod { get }
    var encoding: ParameterEncoding { get }
    var parameters: [String: Any]? { get }
    var headers: HTTPHeaders? { get }
}

extension HTTPTarget {
    func asURLRequest() throws -> URLRequest {
        var url = baseURL

        for pathComponent in pathComponents {
            url.appendPathComponent(pathComponent)
        }

        return try encoding.encode(try URLRequest(url: url, method: method, headers: headers), with: parameters)
    }
}

protocol DecodableTarget: HTTPTarget {
    associatedtype ResultType: Decodable
}
