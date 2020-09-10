// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Combine
import Foundation
import HTTP
import Mastodon
import MastodonAPI

public struct InstanceURLService {
    private let httpClient: HTTPClient
    private var userDefaultsClient: UserDefaultsClient

    public init(environment: AppEnvironment) {
        httpClient = HTTPClient(session: environment.session, decoder: MastodonDecoder())
        userDefaultsClient = UserDefaultsClient(userDefaults: environment.userDefaults)
    }
}

public extension InstanceURLService {
    static func url(text: String) -> URL? {
        guard text.count >= shortestPossibleURLLength else { return nil }

        if text.hasPrefix(httpsPrefix), let prefixedURL = URL(string: text) {
            return prefixedURL
        } else if let unprefixedURL = URL(string: httpsPrefix + text) {
            return unprefixedURL
        }

        return nil
    }

    func instance(url: URL) -> AnyPublisher<Instance?, Never> {
        httpClient.request(
            MastodonAPITarget(
                baseURL: url,
                endpoint: InstanceEndpoint.instance,
                accessToken: nil))
            .map { $0 as Instance? }
            .catch { _ in Just(nil) }
            .eraseToAnyPublisher()
    }

    func isPublicTimelineAvailable(url: URL) -> AnyPublisher<Bool, Never> {
        httpClient.request(
            MastodonAPITarget(
                baseURL: url,
                endpoint: TimelinesEndpoint.public(local: true),
                accessToken: nil))
            .map { _ in true }
            .catch { _ in Just(false) }
            .eraseToAnyPublisher()
    }

    func isFiltered(url: URL) -> Bool {
        guard let host = url.host else { return true }

        let allHostComponents = host.components(separatedBy: ".")
        var hostComponents = [String]()

        for component in allHostComponents.reversed() {
            hostComponents.insert(component, at: 0)

            if filter.contains(hostComponents.joined(separator: ".")) {
                return true
            }
        }

        return false
    }

    func updateFilter() -> AnyPublisher<Never, Never> {
        httpClient.request(UpdatedFilterTarget())
            .handleEvents(receiveOutput: { userDefaultsClient.updatedInstanceFilter = $0 })
            .map { _ in () }
            .replaceError(with: ())
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}

private struct UpdatedFilterTarget: DecodableTarget {
    typealias ResultType = BloomFilter<String>

    let baseURL = URL(string: "https://filter.metabolist.com")!
    let pathComponents = ["filter.json"]
    let method = HTTPMethod.get
    let encoding: ParameterEncoding = JSONEncoding.default
    let parameters: [String: Any]? = nil
    let headers: HTTPHeaders? = nil
}

private extension InstanceURLService {
    static let httpsPrefix = "https://"
    static let shortestPossibleURLLength = 4
    // Ugly, but baking this into the compiled app instead of loading the data from the bundle is more secure
    // swiftlint:disable line_length
    static let defaultFilterData = #"{"hashes":["djb232","djb2a32","fnv132","fnv1a32","sdbm32"],"data":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAIAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAgAAAAAQAAAAAABAAACAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAABAAAEAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAIAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAIAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAIAAAQAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAADAAAAAAAAAAAAA=="}"#
        .data(using: .utf8)!
    // swiftlint:enable line_length
    // swiftlint:disable force_try
    static let defaultFilter = try! JSONDecoder().decode(BloomFilter<String>.self, from: defaultFilterData)
    // swiftlint:enable force_try
    var filter: BloomFilter<String> {
        userDefaultsClient.updatedInstanceFilter ?? Self.defaultFilter
    }
}
