// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import AuthenticationServices
import Combine

protocol WebAuthSession: AnyObject {
    init(url URL: URL,
         callbackURLScheme: String?,
         completionHandler: @escaping WebAuthSessionCompletionHandler)
    var presentationContextProvider: WebAuthPresentationContextProviding? { get set }
    @discardableResult func start() -> Bool
}

extension WebAuthSession {
    static func publisher(
        url: URL,
        callbackURLScheme: String?,
        presentationContextProvider: WebAuthPresentationContextProviding) -> AnyPublisher<URL?, Error> {
        Future<URL?, Error> { promise in
            let webAuthSession = Self(
                url: url,
                callbackURLScheme: callbackURLScheme) { oauthCallbackURL, error in
                if let error = error {
                    return promise(.failure(error))
                }

                return promise(.success(oauthCallbackURL))
            }

            webAuthSession.presentationContextProvider = presentationContextProvider
            webAuthSession.start()
        }
        .eraseToAnyPublisher()
    }
}

class WebAuthSessionContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

typealias WebAuthSessionCompletionHandler = ASWebAuthenticationSession.CompletionHandler
typealias WebAuthSessionError = ASWebAuthenticationSessionError
typealias WebAuthPresentationContextProviding = ASWebAuthenticationPresentationContextProviding
typealias RealWebAuthSession = ASWebAuthenticationSession

extension RealWebAuthSession: WebAuthSession {}
