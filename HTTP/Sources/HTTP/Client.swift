// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Alamofire

public typealias Session = Alamofire.Session

open class Client {
    private let session: Session
    private let decoder: DataDecoder

    public init(session: Session, decoder: DataDecoder) {
        self.session = session
        self.decoder = decoder
    }

    open func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        requestPublisher(target).value().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    public func request<T: DecodableTarget, E: Error & Decodable>(
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

private extension Client {
    func requestPublisher<T: DecodableTarget>(_ target: T) -> DataResponsePublisher<T.ResultType> {
        if let protocolClasses = session.sessionConfiguration.protocolClasses {
            for protocolClass in protocolClasses {
                (protocolClass as? TargetProcessing.Type)?.process(target: target)
            }
        }

        return session.request(target)
            .validate()
            .publishDecodable(type: T.ResultType.self, queue: session.rootQueue, decoder: decoder)
    }
}
