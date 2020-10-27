// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Combine
import Foundation
import HTTP
import Mastodon
import MastodonAPI

public struct InstanceURLService {
    private let httpClient: HTTPClient
    private var appPreferences: AppPreferences

    public init(environment: AppEnvironment) {
        httpClient = HTTPClient(session: environment.session, decoder: MastodonDecoder())
        appPreferences = AppPreferences(environment: environment)
    }
}

public extension InstanceURLService {
    func url(text: String) -> Result<URL, Error> {
        guard text.count >= Self.shortestPossibleURLLength else {
            return .failure(URLError(.badURL))
        }

        let url: URL

        if text.hasPrefix(Self.httpsPrefix), let prefixedURL = URL(string: text) {
            url = prefixedURL
        } else if let unprefixedURL = URL(string: Self.httpsPrefix + text) {
            url = unprefixedURL
        } else {
            return .failure(URLError(.badURL))
        }

        if isFiltered(url: url) {
            return .failure(URLError(.badURL))
        }

        return .success(url)
    }

    func instance(url: URL) -> AnyPublisher<Instance, Error> {
        httpClient.request(
            MastodonAPITarget(
                baseURL: url,
                endpoint: InstanceEndpoint.instance,
                accessToken: nil))
            .eraseToAnyPublisher()
    }

    func isPublicTimelineAvailable(url: URL) -> AnyPublisher<Bool, Error> {
        httpClient.request(
            MastodonAPITarget(
                baseURL: url,
                endpoint: StatusesEndpoint.timelinesPublic(local: true),
                accessToken: nil))
            .map { _ in true }
            .eraseToAnyPublisher()
    }

    func updateFilter() -> AnyPublisher<Never, Error> {
        httpClient.request(UpdatedFilterTarget())
            .handleEvents(receiveOutput: { appPreferences.updateInstanceFilter($0) })
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}

private struct UpdatedFilterTarget: DecodableTarget {
    typealias ResultType = BloomFilter<String>

    let baseURL = URL(string: "https://filter.metabolist.com")!
    let pathComponents = ["filter"]
    let method = HTTPMethod.get
    let queryParameters: [URLQueryItem] = []
    let jsonBody: [String: Any]? = nil
    let headers: [String: String]? = nil
}

private extension InstanceURLService {
    static let httpsPrefix = "https://"
    static let shortestPossibleURLLength = 4
    static let defaultFilter = BloomFilter<String>(
        hashes: [.djb232, .djb2a32, .sdbm32, .fnv132, .fnv1a32],
        data: Data([
            0, 0, 0, 16, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 8, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 2, 2, 8, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 18, 0, 0, 0, 0, 0, 0,
            128, 0, 0, 32, 0, 128, 0, 0, 0, 4, 16, 4, 32, 0, 0, 16, 16, 4, 32, 0, 0, 128, 0, 16, 0, 0, 0, 0, 0, 0, 0, 4,
            0, 0, 0, 0, 4, 0, 0, 3, 2, 0, 0, 0, 4, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 132, 0, 0, 64, 0, 0, 0, 2,
            0, 0, 0, 0, 0, 0, 64, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 1, 0, 0,
            0, 0, 0, 96, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 8, 0, 1, 0, 8, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 160,
            0, 0, 0, 8, 64, 0, 1, 32, 0, 0, 1, 0, 0, 0, 0, 64, 8, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 0, 32, 0, 0, 0, 0, 0, 130, 65, 0, 4, 0, 0, 0, 0,
            0, 0, 0, 8, 0, 0, 0, 0, 128, 65, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 64, 0, 128, 0, 0, 0, 16,
            0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 2, 128, 0, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 8, 0, 0, 0, 0, 0, 0, 0, 16, 0, 1, 48, 0, 0, 0, 2, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0,
            0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 16, 0, 0, 0, 16, 0, 16, 0, 2, 64,
            0, 0, 0, 128, 0, 0, 0, 64, 16, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 8, 0, 0, 0, 4, 8, 0, 64, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 66,
            0, 64, 0, 16, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 1, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 10, 0,
            0, 4, 0, 0, 0, 1, 24, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 128, 4, 64, 0, 128, 0, 0, 0,
            0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 8, 0, 8, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 16, 0, 2, 0, 0, 0,
            0, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 129, 8, 0, 8, 0, 0, 0, 8, 0, 0,
            0, 2, 0, 0, 128, 8, 36, 32, 0, 64, 0, 0, 0, 4, 0, 32, 0, 0, 0, 0, 0, 16, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 8, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 16, 0, 0, 0, 136, 128, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 16, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 64, 0, 64, 0, 0, 0, 16, 0, 0, 0, 8, 0, 0, 0, 0, 16, 0,
            0, 0, 0, 32, 0, 4, 0, 0, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0,
            0, 0, 0, 8, 0, 4, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 160, 0, 0, 0, 4, 0, 0, 16, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 64,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 16, 0, 0, 0, 4, 0, 1, 0, 0, 0, 16, 0, 0,
            0, 0, 0, 0, 0, 0, 128, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 4, 0, 64, 0, 1, 4, 0, 0, 0, 0,
            0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 12, 16, 0, 72, 0, 0, 0, 0, 0, 0
        ]))

    var filter: BloomFilter<String> {
        appPreferences.updatedInstanceFilter ?? Self.defaultFilter
    }

    private func isFiltered(url: URL) -> Bool {
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
}
