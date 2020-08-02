// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class StubbingWebAuthSession: WebAuthSession {
    let completionHandler: WebAuthSessionCompletionHandler
    let url: URL
    let callbackURLScheme: String?
    var presentationContextProvider: WebAuthPresentationContextProviding?

    required init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping WebAuthSessionCompletionHandler) {
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

class SuccessfulStubbingWebAuthSession: StubbingWebAuthSession {
    private let redirectURL: URL

    required init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping WebAuthSessionCompletionHandler) {
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

class CanceledLoginStubbingWebAuthSession: StubbingWebAuthSession {
    override var completionHandlerError: Error? {
        WebAuthSessionError(.canceledLogin)
    }
}
