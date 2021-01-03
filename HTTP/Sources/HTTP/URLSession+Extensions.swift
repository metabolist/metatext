// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

extension URLSession {
    func dataTaskPublisher(for request: URLRequest, progress: Progress?)
    -> AnyPublisher<DataTaskPublisher.Output, Error> {
        if let progress = progress {
            var dataTaskReference: URLSessionDataTask?

            return Deferred {
                Future<DataTaskPublisher.Output, Error> { promise in
                    let dataTask = self.dataTask(with: request) { data, response, error in
                        if let error = error {
                            promise(.failure(error))
                        } else if let data = data, let response = response {
                            promise(.success((data, response)))
                        }
                    }

                    progress.addChild(dataTask.progress, withPendingUnitCount: 1)
                    dataTask.resume()
                    dataTaskReference = dataTask
                }
                .handleEvents(receiveCancel: {
                    dataTaskReference?.cancel()
                })
            }
            .eraseToAnyPublisher()
        } else {
            return dataTaskPublisher(for: request).mapError { $0 as Error }.eraseToAnyPublisher()
        }
    }
}
