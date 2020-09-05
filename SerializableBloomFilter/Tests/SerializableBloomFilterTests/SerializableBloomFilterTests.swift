@testable import SerializableBloomFilter
import XCTest

final class SerializableBloomFilterTests: XCTestCase {
    func testContains() {
        var filter = SerializableBloomFilter()

        filter.insert("lol")
        filter.insert("ok")

        XCTAssert(filter.contains("lol"))
        XCTAssert(filter.contains("ok"))
        XCTAssertFalse(filter.contains("wtf"))
        XCTAssertFalse(filter.contains("no"))
    }

    func testSerialization() throws {
        var filter = SerializableBloomFilter()

        filter.insert("lol")
        filter.insert("ok")

        let serialization = filter.serialization
        let deserializedFilter = try SerializableBloomFilter(serialization: serialization)

        XCTAssert(deserializedFilter.contains("lol"))
        XCTAssert(filter.contains("ok"))
        XCTAssertFalse(deserializedFilter.contains("wtf"))
        XCTAssertFalse(filter.contains("no"))
    }
}
