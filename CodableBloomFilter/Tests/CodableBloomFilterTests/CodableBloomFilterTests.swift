@testable import CodableBloomFilter
import XCTest

final class CodableBloomFilterTests: XCTestCase {
    func testContains() {
        var sut = BloomFilter(hashes: [.djb2, .sdbm], bits: 1024)

        sut.insert("lol")
        sut.insert("ok")

        XCTAssert(sut.contains("lol"))
        XCTAssert(sut.contains("ok"))
        XCTAssertFalse(sut.contains("wtf"))
        XCTAssertFalse(sut.contains("no"))
    }

    func testCoding() throws {
        var sut = BloomFilter(hashes: [.djb2, .sdbm], bits: 64)
        let expectedSerialization = Data(#"{"bits":64,"data":"ABAAAAACAJA=","hashes":["djb2","sdbm"]}"#.utf8)

        sut.insert("lol")
        sut.insert("ok")

        let encoder = JSONEncoder()

        encoder.outputFormatting = .sortedKeys

        let serialization = try encoder.encode(sut)

        XCTAssertEqual(serialization, expectedSerialization)

        let decoded = try JSONDecoder().decode(BloomFilter.self, from: serialization)

        XCTAssert(decoded.contains("lol"))
        XCTAssert(decoded.contains("ok"))
        XCTAssertFalse(decoded.contains("wtf"))
        XCTAssertFalse(decoded.contains("no"))
    }
}
