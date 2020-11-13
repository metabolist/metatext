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

        if case .failure = sut.url(text: "unfiltered.instance") {
            XCTFail("Expected success")
        }

        if case .success = sut.url(text: "filtered.instance") {
            XCTFail("Expected failure")
        }

        if case .success = sut.url(text: "subdomain.filtered.instance") {
            XCTFail("Expected failure")
        }
    }

    func testUpdating() throws {
        let environment = AppEnvironment.mock()
        var sut = InstanceURLService(environment: environment)

        if case .success = sut.url(text: "filtered.instance") {
            XCTFail("Expected failure")
        }

        if case .failure = sut.url(text: "instance.filtered") {
            XCTFail("Expected success")
        }

        var updatedFilter = BloomFilter<String>(hashes: [.djb232, .sdbm32], byteCount: 16)

        updatedFilter.insert("instance.filtered")

        let updatedFilterData = try JSONEncoder().encode(updatedFilter)
        let stub: HTTPStub = .success((HTTPURLResponse(), updatedFilterData))

        StubbingURLProtocol.setStub(stub, forURL: URL(string: "https://filter.metabolist.com/filter")!)

        let updateRecorder = sut.updateFilter().collect().record()

        _ = try wait(for: updateRecorder.next(), timeout: 1)

        if case .failure = sut.url(text: "filtered.instance") {
            XCTFail("Expected success")
        }

        if case .success = sut.url(text: "instance.filtered") {
            XCTFail("Expected failure")
        }

        sut = InstanceURLService(environment: environment)

        if case .failure = sut.url(text: "filtered.instance") {
            XCTFail("Expected success")
        }

        if case .success = sut.url(text: "instance.filtered") {
            XCTFail("Expected failure")
        }
    }
}
