// Copyright © 2020 Metabolist. All rights reserved.

import AuthenticationServices
import Combine
import Foundation

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
        presentationContextProvider: WebAuthPresentationContextProviding) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { promise in
            let webAuthSession = Self(
                url: url,
                callbackURLScheme: callbackURLScheme) { oauthCallbackURL, error in
                if let error = error {
                    promise(.failure(error))
                } else if let oauthCallbackURL = oauthCallbackURL {
                    promise(.success(oauthCallbackURL))
                } else {
                    promise(.failure(URLError(.unknown)))
                }
            }

            webAuthSession.presentationContextProvider = presentationContextProvider

            DispatchQueue.main.async {
                webAuthSession.start()
            }
        }
        .eraseToAnyPublisher()
    }
}

final class WebAuthSessionContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

public typealias WebAuthSessionCompletionHandler = ASWebAuthenticationSession.CompletionHandler
public typealias WebAuthSessionError = ASWebAuthenticationSessionError
public typealias WebAuthPresentationContextProviding = ASWebAuthenticationPresentationContextProviding
public typealias LiveWebAuthSession = ASWebAuthenticationSession

extension LiveWebAuthSession: WebAuthSession {}
