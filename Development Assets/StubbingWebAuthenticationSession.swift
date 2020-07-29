// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import AuthenticationServices

class StubbingWebAuthenticationSession: WebAuthenticationSessionType {
    let completionHandler: ASWebAuthenticationSession.CompletionHandler
    let url: URL
    let callbackURLScheme: String?
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

    required init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        self.url = URL
        self.callbackURLScheme = callbackURLScheme
        self.completionHandler = completionHandler
    }

    func start() -> Bool {
        completionHandler(completionHandlerURL, completionHandlerError)

        return true
    }

    var completionHandlerURL: URL? {
        nil
    }

    var completionHandlerError: Error? {
        nil
    }
}

// swiftlint:disable type_name
class SuccessfulStubbingWebAuthenticationSession: StubbingWebAuthenticationSession {
// swiftlint:enable type_name
    private let redirectURL: URL

    required init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        redirectURL = Foundation.URL(
            string: URLComponents(url: URL, resolvingAgainstBaseURL: true)!
                .queryItems!.first(where: { $0.name == "redirect_uri" })!.value!)!
        super.init(
            url: URL,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler)
    }

    override var completionHandlerURL: URL? {
        var components = URLComponents(url: redirectURL, resolvingAgainstBaseURL: true)!
        var queryItems = components.queryItems ?? []

        queryItems.append(URLQueryItem(name: "code", value: UUID().uuidString))
        components.queryItems = queryItems

        return components.url
    }
}

// swiftlint:disable type_name
class CanceledLoginStubbingWebAuthenticationSession: StubbingWebAuthenticationSession {
// swiftlint:enable type_name
    override var completionHandlerError: Error? {
        ASWebAuthenticationSessionError(.canceledLogin)
    }
}
