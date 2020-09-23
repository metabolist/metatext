// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol Target {
    var baseURL: URL { get }
    var pathComponents: [String] { get }
    var method: HTTPMethod { get }
    var queryParameters: [String: String]? { get }
    var jsonBody: [String: Any]? { get }
    var headers: [String: String]? { get }
}

public extension Target {
    func urlRequest() -> URLRequest {
        var url = baseURL

        for pathComponent in pathComponents {
            url.appendPathComponent(pathComponent)
        }

        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = queryParameters?.map(URLQueryItem.init(name:value:)) {
            components.queryItems = queryItems

            if let queryComponentURL = components.url {
                url = queryComponentURL
            }
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers

        if let jsonBody = jsonBody {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody)
        }

        return urlRequest
    }
}

public protocol DecodableTarget: Target {
    associatedtype ResultType: Decodable
}

public protocol TargetProcessing {
    static func process(target: Target)
}
