// Copyright © 2020 Metabolist. All rights reserved.

@testable import CodableBloomFilter
import XCTest

final class CodableBloomFilterTests: XCTestCase {

    func testHashers() {
        XCTAssertEqual(DeterministicHasher.djb2.apply("hash"), 2090320585)
        XCTAssertEqual(DeterministicHasher.djb2a.apply("hash"), 2087809207)
        XCTAssertEqual(DeterministicHasher.sdbm.apply("hash"), 385600046)
        XCTAssertEqual(DeterministicHasher.fnv1.apply("hash"), 3616638997)
        XCTAssertEqual(DeterministicHasher.fnv1a.apply("hash"), 3469047761)
    }

    func testContains() {
        var sut = BloomFilter<String>(hashers: [.djb2, .sdbm, .fnv1, .fnv1a], byteCount: 128)

        sut.insert("lol")
        sut.insert("ok")

        XCTAssert(sut.contains("lol"))
        XCTAssert(sut.contains("ok"))
        XCTAssertFalse(sut.contains("wtf"))
        XCTAssertFalse(sut.contains("no"))
    }

    func testCoding() throws {
        var sut = BloomFilter<String>(hashers: [.sdbm, .djb2], byteCount: 8)
        let expectedSerialization = Data(#"{"data":"ABAAAAACAJA=","hashers":["djb2","sdbm"]}"#.utf8)

        sut.insert("lol")
        sut.insert("ok")

        let encoder = JSONEncoder()

        encoder.outputFormatting = .sortedKeys

        let serialization = try encoder.encode(sut)

        XCTAssertEqual(serialization, expectedSerialization)

        let decoded = try JSONDecoder().decode(BloomFilter<String>.self, from: serialization)

        XCTAssert(decoded.contains("lol"))
        XCTAssert(decoded.contains("ok"))
        XCTAssertFalse(decoded.contains("wtf"))
        XCTAssertFalse(decoded.contains("no"))
    }
}
