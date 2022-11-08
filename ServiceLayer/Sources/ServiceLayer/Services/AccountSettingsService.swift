//
//  File.swift
//  
//
//  Created by Justin Mazzocchi on 11/8/22.
//

import Combine
import Foundation

public struct AccountSettingsService {
    private let instanceURI: String
    private let webAuthSessionType: WebAuthSession.Type
    private let webAuthSessionContextProvider = WebAuthSessionContextProvider()

    public init(instanceURI: String, environment: AppEnvironment) {
        self.instanceURI = instanceURI
        webAuthSessionType = environment.webAuthSessionType
    }
}

public extension AccountSettingsService {
    func openAccountSettings() -> AnyPublisher<URL, Error> {
        guard let url = URL(string: "https://\(instanceURI)/auth/edit") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        print(webAuthSessionContextProvider)

        return webAuthSessionType.publisher(
            url: url,
            callbackURLScheme: nil,
            presentationContextProvider: webAuthSessionContextProvider)
    }
}

private extension AccountSettingsService {
    func accountSettingsURL(instanceURI: String) -> URL? {
        URL(string: "https://\(instanceURI)/auth/edit")
    }
}
