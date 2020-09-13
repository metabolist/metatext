// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Combine
import CombineExpectations
@testable import ServiceLayer
@testable import ServiceLayerMocks
import Stubbing
import XCTest

class InstanceURLServiceTests: XCTestCase {
    func testFiltering() throws {
        let sut = InstanceURLService(environment: .mock())

        XCTAssertNotNil(sut.url(text: "unfiltered.instance"))
        XCTAssertNil(sut.url(text: "filtered.instance"))
        XCTAssertNil(sut.url(text: "subdomain.filtered.instance"))
    }

    func testUpdating() throws {
        let environment = AppEnvironment.mock()
        var sut = InstanceURLService(environment: environment)

        XCTAssertNil(sut.url(text: "filtered.instance"))
        XCTAssertNotNil(sut.url(text: "instance.filtered"))

        var updatedFilter = try BloomFilter<String>(hashes: [.djb232, .sdbm32], byteCount: 16)

        updatedFilter.insert("instance.filtered")

        let updatedFilterData = try JSONEncoder().encode(updatedFilter)
        let stub: HTTPStub = .success((URLResponse(), updatedFilterData))

        StubbingURLProtocol.setStub(stub, forURL: URL(string: "https://filter.metabolist.com/filter")!)

        let updateRecorder = sut.updateFilter().collect().record()

        _ = try wait(for: updateRecorder.next(), timeout: 1)

        XCTAssertNotNil(sut.url(text: "filtered.instance"))
        XCTAssertNil(sut.url(text: "instance.filtered"))

        sut = InstanceURLService(environment: environment)

        XCTAssertNotNil(sut.url(text: "filtered.instance"))
        XCTAssertNil(sut.url(text: "instance.filtered"))
    }
}
