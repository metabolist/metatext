// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Alamofire

class HTTPClient {
    private let session: Session
    private let decoder: DataDecoder

    init(configuration: URLSessionConfiguration, decoder: DataDecoder = JSONDecoder()) {
        self.session = Session(configuration: configuration)
        self.decoder = decoder
    }

    func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        requestPublisher(target).value().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func request<T: DecodableTarget, E: Error & Decodable>(
        _ target: T,
        decodeErrorsAs errorType: E.Type) -> AnyPublisher<T.ResultType, Error> {
        let decoder = self.decoder

        return requestPublisher(target)
            .tryMap { response -> T.ResultType in
                switch response.result {
                case let .success(decoded): return decoded
                case let .failure(error):
                    if
                        let data = response.data,
                        let decodedError = try? decoder.decode(E.self, from: data) {
                        throw decodedError
                    }

                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension HTTPClient {
    private func requestPublisher<T: DecodableTarget>(_ target: T) -> DataResponsePublisher<T.ResultType> {
        #if DEBUG
        if let url = try? target.asURLRequest().url {
            StubbingURLProtocol.setTarget(target, forURL: url)
        }
        #endif

        return session.request(target)
            .validate()
            .publishDecodable(type: T.ResultType.self, decoder: decoder)
    }
}
