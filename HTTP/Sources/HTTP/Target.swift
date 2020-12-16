// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol Target {
    var baseURL: URL { get }
    var pathComponents: [String] { get }
    var method: HTTPMethod { get }
    var queryParameters: [URLQueryItem] { get }
    var jsonBody: [String: Any]? { get }
    var multipartFormData: [String: MultipartFormValue]? { get }
    var headers: [String: String]? { get }
}

public extension Target {
    func urlRequest() -> URLRequest {
        var url = baseURL

        for pathComponent in pathComponents {
            url.appendPathComponent(pathComponent)
        }

        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true), !queryParameters.isEmpty {
            components.queryItems = queryParameters

            if let queryComponentURL = components.url {
                url = queryComponentURL
            }
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers

        if let jsonBody = jsonBody {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody)
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        } else if let multipartFormData = multipartFormData {
            let boundary = "Boundary-\(UUID().uuidString)"
            var httpBody = Data()

            for (key, value) in multipartFormData {
                httpBody.append(value.httpBodyComponent(boundary: boundary, key: key))
            }

            httpBody.append(Data("--\(boundary)--".utf8))
            urlRequest.httpBody = httpBody
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
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
