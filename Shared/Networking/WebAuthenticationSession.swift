// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import AuthenticationServices
import Combine

protocol WebAuthenticationSessionType: AnyObject {
    init(url URL: URL,
         callbackURLScheme: String?,
         completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler)
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? { get set }
    @discardableResult func start() -> Bool
}

extension ASWebAuthenticationSession: WebAuthenticationSessionType {}

extension WebAuthenticationSessionType {
    static func publisher(
        url: URL,
        callbackURLScheme: String?,
        presentationContextProvider: ASWebAuthenticationPresentationContextProviding) -> AnyPublisher<URL?, Error> {
        Future<URL?, Error> { promise in
            let webAuthenticationSession = Self(
                url: url,
                callbackURLScheme: callbackURLScheme) { oauthCallbackURL, error in
                if let error = error {
                    return promise(.failure(error))
                }

                return promise(.success(oauthCallbackURL))
            }

            webAuthenticationSession.presentationContextProvider = presentationContextProvider
            webAuthenticationSession.start()
        }
        .eraseToAnyPublisher()
    }
}
