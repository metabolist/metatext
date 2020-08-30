// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

class StubbingURLProtocol: URLProtocol {
    private static var targetsForURLs = [URL: HTTPTarget]()

    class func setTarget(_ target: HTTPTarget, forURL url: URL) {
        targetsForURLs[url] = target
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let stub = HTTPStubs.stub(request: request, target: Self.targetsForURLs[url]) else {
            preconditionFailure("Stub for request not found")
        }

        switch stub {
        case let .success((response, data)):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
