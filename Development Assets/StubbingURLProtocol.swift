// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

class StubbingURLProtocol: URLProtocol {
    private static var targetsForURLs = [URL: Target]()

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

extension StubbingURLProtocol: TargetProcessing {
    static func process(target: Target) {
        if let url = try? target.asURLRequest().url {
            targetsForURLs[url] = target
        }
    }
}
