// Copyright © 2020 Metabolist. All rights reserved.

@testable import CodableBloomFilter
import XCTest

final class CodableBloomFilterTests: XCTestCase {
    func testHashes() {
        XCTAssertEqual(Hash.djb232.apply("hash"), 2090320585)
        XCTAssertEqual(Hash.djb2a32.apply("hash"), 2087809207)
        XCTAssertEqual(Hash.sdbm32.apply("hash"), 385600046)
        XCTAssertEqual(Hash.fnv132.apply("hash"), 3616638997)
        XCTAssertEqual(Hash.fnv1a32.apply("hash"), 3469047761)
    }

    func noHashesProvided() throws {
        XCTAssertThrowsError(try BloomFilter<String>(hashes: [], byteCount: 8)) {
            guard case BloomFilterError.noHashesProvided = $0 else {
                XCTFail("Expected no hashers provided error")

                return
            }
        }
    }

    func testContains() throws {
        var sut = try BloomFilter<String>(hashes: [.sdbm32, .djb232], byteCount: 8)

        sut.insert("lol")
        sut.insert("ok")

        XCTAssert(sut.contains("lol"))
        XCTAssert(sut.contains("ok"))
        XCTAssertFalse(sut.contains("wtf"))
        XCTAssertFalse(sut.contains("no"))
    }

    func testData() throws {
        var sut = try BloomFilter<String>(hashes: [.sdbm32, .djb232], byteCount: 8)

        sut.insert("lol")
        sut.insert("ok")

        XCTAssertEqual(sut.data, Data([0, 16, 0, 0, 0, 2, 0, 144]))
    }

    func testFromData() throws {
        let sut = try BloomFilter<String>(hashes: [.sdbm32, .djb232], data: Data([0, 16, 0, 0, 0, 2, 0, 144]))

        XCTAssert(sut.contains("lol"))
        XCTAssert(sut.contains("ok"))
        XCTAssertFalse(sut.contains("wtf"))
        XCTAssertFalse(sut.contains("no"))
    }

    func testCoding() throws {
        var sut = try BloomFilter<String>(hashes: [.sdbm32, .djb232], byteCount: 8)
        let expectedData = Data(#"{"data":"ABAAAAACAJA=","hashes":["djb232","sdbm32"]}"#.utf8)

        sut.insert("lol")
        sut.insert("ok")

        let encoder = JSONEncoder()

        encoder.outputFormatting = .sortedKeys

        let data = try encoder.encode(sut)

        XCTAssertEqual(data, expectedData)

        let decoded = try JSONDecoder().decode(BloomFilter<String>.self, from: data)

        XCTAssert(decoded.contains("lol"))
        XCTAssert(decoded.contains("ok"))
        XCTAssertFalse(decoded.contains("wtf"))
        XCTAssertFalse(decoded.contains("no"))
    }

    func testInvalidHash() throws {
        let invalidData = Data(#"{"data":"ABAAAAACAJA=","hashes":["djb232","invalid"]}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(BloomFilter<String>.self, from: invalidData)) {
            guard case DecodingError.dataCorrupted = $0 else {
                XCTFail("Expected data corrupted error")

                return
            }
        }
    }

    func testDataEncodingStrategy() throws {
        var sut = try BloomFilter<String>(hashes: [.sdbm32, .djb232], byteCount: 8)
        let expectedData = Data(#"{"data":"0010000000020090","hashes":["djb232","sdbm32"]}"#.utf8)

        sut.insert("lol")
        sut.insert("ok")

        let encoder = JSONEncoder()

        encoder.outputFormatting = .sortedKeys
        encoder.dataEncodingStrategy = .custom { data, encoder in
            var container = encoder.singleValueContainer()

            try container.encode(data.map { String(format: "%02.2hhx", $0) }.joined())
        }

        let data = try encoder.encode(sut)

        XCTAssertEqual(data, expectedData)
    }

    func testDataDecodingStrategy() throws {
        let data = Data(#"{"data":"0010000000020090","hashes":["djb232","sdbm32"]}"#.utf8)
        let decoder = JSONDecoder()

        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            var bytes = [UInt8]()
            var i = string.startIndex

            while i != string.endIndex {
                let j = string.index(i, offsetBy: 2)

                guard let byte = UInt8(string[i..<j], radix: 16) else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid byte")
                }

                bytes.append(byte)
                i = j
            }

            return Data(bytes)
        }

        let sut = try decoder.decode(BloomFilter<String>.self, from: data)

        XCTAssert(sut.contains("lol"))
        XCTAssert(sut.contains("ok"))
        XCTAssertFalse(sut.contains("wtf"))
        XCTAssertFalse(sut.contains("no"))
    }
}
