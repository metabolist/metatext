// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

public class StubbingURLProtocol: URLProtocol {
    private static var targetsForURLs = [URL: Target]()

    override public class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        guard
            let url = request.url,
            let stub = Self.stub(request: request, target: Self.targetsForURLs[url]) else {
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

    override public func stopLoading() {}
}

private extension StubbingURLProtocol {
    class func stub(
        request: URLRequest,
        target: Target? = nil,
        userInfo: [String: Any] = [:]) -> HTTPStub? {
        guard let url = request.url else {
            return nil
        }

        return (target as? Stubbing)?.stub(url: url)
    }
}

extension StubbingURLProtocol: TargetProcessing {
    public static func process(target: Target) {
        if let url = try? target.asURLRequest().url {
            targetsForURLs[url] = target
        }
    }
}
