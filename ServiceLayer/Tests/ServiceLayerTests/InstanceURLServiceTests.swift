// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Combine
import CombineExpectations
@testable import ServiceLayer
@testable import ServiceLayerMocks
import Stubbing
import XCTest

final class InstanceURLServiceTests: XCTestCase {
    func testFiltering() throws {
        let sut = InstanceURLService(environment: .mock())

        guard case .success = sut.url(text: "unfiltered.instance") else {
            XCTFail("Expected success")

            return
        }

        guard case let .failure(error) = sut.url(text: "filtered.instance"),
              case InstanceURLError.instanceNotSupported = error
        else {
            XCTFail("Expected instance not supported error")

            return
        }

        guard case .failure = sut.url(text: "subdomain.filtered.instance"),
              case InstanceURLError.instanceNotSupported = error
        else {
            XCTFail("Expected instance not supported error")

            return
        }
    }

    func testUpdating() throws {
        let environment = AppEnvironment.mock()
        var sut = InstanceURLService(environment: environment)

        guard case let .failure(error0) = sut.url(text: "filtered.instance"),
              case InstanceURLError.instanceNotSupported = error0
        else {
            XCTFail("Expected instance not supported error")

            return
        }

        guard case .success = sut.url(text: "instance.filtered") else {
            XCTFail("Expected success")

            return
        }

        var updatedFilter = BloomFilter<String>(hashes: [.djb232, .sdbm32], byteCount: 16)

        updatedFilter.insert("instance.filtered")

        let updatedFilterData = try JSONEncoder().encode(updatedFilter)
        let stub: HTTPStub = .success((HTTPURLResponse(), updatedFilterData))

        StubbingURLProtocol.setStub(stub, forURL: URL(string: "https://filter.metabolist.com/filter")!)

        let updateRecorder = sut.updateFilter().collect().record()

        _ = try wait(for: updateRecorder.next(), timeout: 1)

        guard case .success = sut.url(text: "filtered.instance") else {
            XCTFail("Expected success")

            return
        }

        guard case let .failure(error1) = sut.url(text: "instance.filtered"),
              case InstanceURLError.instanceNotSupported = error1
        else {
            XCTFail("Expected instance not supported error")

            return
        }

        sut = InstanceURLService(environment: environment)

        guard case .success = sut.url(text: "filtered.instance") else {
            XCTFail("Expected success")

            return
        }

        guard case let .failure(error2) = sut.url(text: "instance.filtered"),
              case InstanceURLError.instanceNotSupported = error2
        else {
            XCTFail("Expected instance not supported error")

            return
        }
    }
}
