// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public enum HTTPError: Error {
    case nonHTTPURLResponse(data: Data, response: URLResponse)
    case invalidStatusCode(data: Data, response: HTTPURLResponse)
}

open class HTTPClient {
    public let decoder: JSONDecoder

    private let session: URLSession

    public init(session: URLSession, decoder: JSONDecoder) {
        self.session = session
        self.decoder = decoder
    }

    open func dataTaskPublisher<T: DecodableTarget>(
        _ target: T, progress: Progress? = nil) -> AnyPublisher<(data: Data, response: HTTPURLResponse), Error> {
        if let protocolClasses = session.configuration.protocolClasses {
            for protocolClass in protocolClasses {
                (protocolClass as? TargetProcessing.Type)?.process(target: target)
            }
        }

        return session.dataTaskPublisher(for: target.urlRequest(), progress: progress)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPError.nonHTTPURLResponse(data: data, response: response)
                }

                guard Self.validStatusCodes.contains(httpResponse.statusCode) else {
                    throw HTTPError.invalidStatusCode(data: data, response: httpResponse)
                }

                return (data, httpResponse)
            }
            .eraseToAnyPublisher()
    }

    open func request<T: DecodableTarget>(_ target: T, progress: Progress? = nil) -> AnyPublisher<T.ResultType, Error> {
        dataTaskPublisher(target, progress: progress)
            .map(\.data)
            .decode(type: T.ResultType.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

public extension HTTPClient {
    static let validStatusCodes = 200..<300
}
