// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import AuthenticationServices
import Combine

public protocol WebAuthSession: AnyObject {
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

public typealias WebAuthSessionCompletionHandler = ASWebAuthenticationSession.CompletionHandler
public typealias WebAuthSessionError = ASWebAuthenticationSessionError
public typealias WebAuthPresentationContextProviding = ASWebAuthenticationPresentationContextProviding
public typealias LiveWebAuthSession = ASWebAuthenticationSession

extension LiveWebAuthSession: WebAuthSession {}
