// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Combine
import CombineExpectations
@testable import ServiceLayer
@testable import ServiceLayerMocks
import Stubbing
import XCTest

class InstanceFilterServiceTests: XCTestCase {
    func testFiltering() throws {
        let sut = InstanceFilterService(environment: .mock())
        let unfilteredInstanceURL = URL(string: "https://unfiltered.instance")!
        let filteredInstanceURL = URL(string: "https://filtered.instance")!
        let subdomainFilteredInstanceURL = URL(string: "https://subdomain.filtered.instance")!

        XCTAssertFalse(sut.isFiltered(url: unfilteredInstanceURL))
        XCTAssertTrue(sut.isFiltered(url: filteredInstanceURL))
        XCTAssertTrue(sut.isFiltered(url: subdomainFilteredInstanceURL))
    }

    func testUpdating() throws {
        let environment = AppEnvironment.mock()
        var sut = InstanceFilterService(environment: environment)
        let previouslyFilteredInstanceURL = URL(string: "https://filtered.instance")!
        let newlyFilteredInstanceURL = URL(string: "https://instance.filtered")!

        XCTAssertTrue(sut.isFiltered(url: previouslyFilteredInstanceURL))
        XCTAssertFalse(sut.isFiltered(url: newlyFilteredInstanceURL))

        var updatedFilter = BloomFilter<String>(hashers: [.djb2, .sdbm], byteCount: 16)

        updatedFilter.insert("instance.filtered")

        let updatedFilterData = try JSONEncoder().encode(updatedFilter)
        let stub: HTTPStub = .success((URLResponse(), updatedFilterData))

        StubbingURLProtocol.setStub(stub, forURL: URL(string: "https://filter.metabolist.com/filter.json")!)

        let updateRecorder = sut.updateFilter().collect().record()

        _ = try wait(for: updateRecorder.next(), timeout: 1)

        XCTAssertFalse(sut.isFiltered(url: previouslyFilteredInstanceURL))
        XCTAssertTrue(sut.isFiltered(url: newlyFilteredInstanceURL))

        sut = InstanceFilterService(environment: environment)

        XCTAssertFalse(sut.isFiltered(url: previouslyFilteredInstanceURL))
        XCTAssertTrue(sut.isFiltered(url: newlyFilteredInstanceURL))
    }
}
