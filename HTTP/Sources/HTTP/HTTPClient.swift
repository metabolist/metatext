// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public enum HTTPError: Error {
    case invalidStatusCode(HTTPURLResponse)
}

open class HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession, decoder: JSONDecoder) {
        self.session = session
        self.decoder = decoder
    }

    open func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        dataTaskPublisher(target)
            .map(\.data)
            .decode(type: T.ResultType.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    public func request<T: DecodableTarget, E: Error & Decodable>(
        _ target: T,
        decodeErrorsAs errorType: E.Type) -> AnyPublisher<T.ResultType, Error> {
        let decoder = self.decoder

        return dataTaskPublisher(target)
            .tryMap { result -> Data in
                if
                    let response = result.response as? HTTPURLResponse,
                    !Self.validStatusCodes.contains(response.statusCode) {

                    if let decodedError = try? decoder.decode(E.self, from: result.data) {
                        throw decodedError
                    } else {
                        throw HTTPError.invalidStatusCode(response)
                    }
                }

                return result.data
            }
            .decode(type: T.ResultType.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

private extension HTTPClient {
    static let validStatusCodes = 200..<300
    func dataTaskPublisher<T: DecodableTarget>(_ target: T) -> URLSession.DataTaskPublisher {
        if let protocolClasses = session.configuration.protocolClasses {
            for protocolClass in protocolClasses {
                (protocolClass as? TargetProcessing.Type)?.process(target: target)
            }
        }

        return session.dataTaskPublisher(for: target.urlRequest())

//        return session.request(target.urlRequest())
//            .validate()
//            .publishDecodable(type: T.ResultType.self, queue: session.rootQueue, decoder: decoder)
    }
}
