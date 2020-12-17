// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import HTTP
import Mastodon

public final class MastodonAPIClient: HTTPClient {
    public var instanceURL: URL
    public var accessToken: String?

    public required init(session: URLSession, instanceURL: URL) {
        self.instanceURL = instanceURL
        super.init(session: session, decoder: MastodonDecoder())
    }

    public override func dataTaskPublisher<T: DecodableTarget>(
        _ target: T, progress: Progress? = nil) -> AnyPublisher<(data: Data, response: HTTPURLResponse), Error> {
        super.dataTaskPublisher(target, progress: progress)
            .mapError { [weak self] error -> Error in
                if case let HTTPError.invalidStatusCode(data, _) = error,
                   let apiError = try? self?.decoder.decode(APIError.self, from: data) {
                    return apiError
                }

                return error
            }
            .eraseToAnyPublisher()
    }
}

extension MastodonAPIClient {
    public func request<E: Endpoint>(_ endpoint: E, progress: Progress? = nil) -> AnyPublisher<E.ResultType, Error> {
        dataTaskPublisher(target(endpoint: endpoint), progress: progress)
            .map(\.data)
            .decode(type: E.ResultType.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    public func pagedRequest<E: Endpoint>(
        _ endpoint: E,
        maxId: String? = nil,
        minId: String? = nil,
        sinceId: String? = nil,
        limit: Int? = nil,
        progress: Progress? = nil) -> AnyPublisher<PagedResult<E.ResultType>, Error> {
        let pagedTarget = target(endpoint: Paged(endpoint, maxId: maxId, minId: minId, sinceId: sinceId, limit: limit))
        let dataTask = dataTaskPublisher(pagedTarget, progress: progress).share()
        let decoded = dataTask.map(\.data).decode(type: E.ResultType.self, decoder: decoder)
        let info = dataTask.map { _, response -> PagedResult<E.ResultType>.Info in
            var maxId: String?
            var minId: String?
            var sinceId: String?

            if let links = response.value(forHTTPHeaderField: "Link") {
                let queryItems = Self.linkDataDetector.matches(
                    in: links,
                    range: .init(links.startIndex..<links.endIndex, in: links))
                    .compactMap { match -> [URLQueryItem]? in
                        guard let url = match.url else { return nil }

                        return URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
                    }
                    .reduce([], +)

                maxId = queryItems.first { $0.name == "max_id" }?.value
                minId = queryItems.first { $0.name == "min_id" }?.value
                sinceId = queryItems.first { $0.name == "since_id" }?.value
            }

            return PagedResult.Info(maxId: maxId, minId: minId, sinceId: sinceId)
        }

        return decoded.zip(info).map(PagedResult.init(result:info:)).eraseToAnyPublisher()
    }
}

private extension MastodonAPIClient {
    // swiftlint:disable force_try
    static let linkDataDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    // swiftlint:enable force_try

    func target<E: Endpoint>(endpoint: E) -> MastodonAPITarget<E> {
        MastodonAPITarget(baseURL: instanceURL, endpoint: endpoint, accessToken: accessToken)
    }
}
