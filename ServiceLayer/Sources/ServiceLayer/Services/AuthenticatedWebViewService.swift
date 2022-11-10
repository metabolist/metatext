// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

public struct AuthenticatedWebViewService {
    private let environment: AppEnvironment
    private let webAuthSessionContextProvider = WebAuthSessionContextProvider()

    public init(environment: AppEnvironment) {
        self.environment = environment
    }
}

public extension AuthenticatedWebViewService {
    func authenticatedWebViewPublisher(url: URL) -> AnyPublisher<URL, Error> {
        environment.webAuthSessionType.publisher(
            url: url,
            callbackURLScheme: nil,
            presentationContextProvider: webAuthSessionContextProvider)
    }
}
