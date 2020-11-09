// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

public final class StubbingURLProtocol: URLProtocol {
    private static var targetsForURLs = [URL: Target]()
    private static var stubsForURLs = [URL: HTTPStub]()

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
            let stub = Self.stubsForURLs[url]
                ?? Self.stub(request: request, target: Self.targetsForURLs[url]) else {
            return
        }

        switch stub {
        case let .success((response, data)):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override public func stopLoading() {}
}

public extension StubbingURLProtocol {
    static func setStub(_ stub: HTTPStub, forURL url: URL) {
        stubsForURLs[url] = stub
    }
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
        if let url = target.urlRequest().url {
            targetsForURLs[url] = target
        }
    }
}
