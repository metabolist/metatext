// Copyright © 2020 Metabolist. All rights reserved.

@testable import Base16
import XCTest

final class Base16Tests: XCTestCase {
    let testData = Data([182, 239, 215, 173, 251, 168, 76, 252,
                         140, 7, 39, 163, 56, 255, 171, 35,
                         121, 205, 26, 252, 53, 166, 159, 67,
                         100, 70, 140, 79, 47, 26, 138, 209])
    let testDataLowercaseString = "b6efd7adfba84cfc8c0727a338ffab2379cd1afc35a69f4364468c4f2f1a8ad1"
    let testDataLowercaseStringData = Data([98, 54, 101, 102, 100, 55, 97, 100,
                                            102, 98, 97, 56, 52, 99, 102, 99,
                                            56, 99, 48, 55, 50, 55, 97, 51, 51,
                                            56, 102, 102, 97, 98, 50, 51, 55,
                                            57, 99, 100, 49, 97, 102, 99, 51,
                                            53, 97, 54, 57, 102, 52, 51, 54,
                                            52, 52, 54, 56, 99, 52, 102, 50,
                                            102, 49, 97, 56, 97, 100, 49])
    let testDataUppercaseString = "B6EFD7ADFBA84CFC8C0727A338FFAB2379CD1AFC35A69F4364468C4F2F1A8AD1"
    let testDataUppercaseStringData = Data([66, 54, 69, 70, 68, 55, 65, 68,
                                            70, 66, 65, 56, 52, 67, 70, 67,
                                            56, 67, 48, 55, 50, 55, 65, 51,
                                            51, 56, 70, 70, 65, 66, 50, 51,
                                            55, 57, 67, 68, 49, 65, 70, 67,
                                            51, 53, 65, 54, 57, 70, 52, 51,
                                            54, 52, 52, 54, 56, 67, 52, 70,
                                            50, 70, 49, 65, 56, 65, 68, 49])

    func testLowercaseString() {
        XCTAssertEqual(testData.base16EncodedString(), testDataLowercaseString)
    }

    func testUppercaseString() {
        XCTAssertEqual(testData.base16EncodedString(options: [.uppercase]),
                       testDataUppercaseString)
    }

    func testLowercaseData() {
        XCTAssertEqual(testData.base16EncodedData(), testDataLowercaseStringData)
    }

    func testUppercaseData() {
        XCTAssertEqual(testData.base16EncodedData(options: [.uppercase]),
                       testDataUppercaseStringData)
    }

    func testInitializationFromLowercaseString() throws {
        XCTAssertEqual(try Data(base16Encoded: testDataLowercaseString), testData)
    }

    func testInitializationFromUppercaseString() throws {
        XCTAssertEqual(try Data(base16Encoded: testDataUppercaseString), testData)
    }

    func testInitializationFromLowercaseData() throws {
        XCTAssertEqual(try Data(base16Encoded: testDataLowercaseStringData), testData)
    }

    func testInitializationFromUppercaseData() throws {
        XCTAssertEqual(try Data(base16Encoded: testDataUppercaseStringData), testData)
    }

    func testInvalidLength() throws {
        let invalidLength = String(testDataLowercaseString.prefix(testDataLowercaseString.count - 1))

        XCTAssertThrowsError(try Data(base16Encoded: invalidLength)) {
            guard case Base16EncodingError.invalidLength = $0 else {
                XCTFail("Expected invalid length error")

                return
            }
        }
    }

    func testInvalidByteString() {
        let invalidString = testDataLowercaseString.replacingOccurrences(of: "a", with: "z")

        XCTAssertThrowsError(try Data(base16Encoded: invalidString)) {
            guard case let Base16EncodingError.invalidByteString(invalidByteString) = $0 else {
                XCTFail("Expected invalid byte string error")

                return
            }

            XCTAssertEqual(invalidByteString, "zd")
        }
    }

    func testInvalidStringEncoding() {
        let invalidData = testDataLowercaseString.data(using: .utf16)!

        XCTAssertThrowsError(try Data(base16Encoded: invalidData)) {
            guard case Base16EncodingError.invalidStringEncoding = $0 else {
                XCTFail("Expected string encoding error")

                return
            }
        }
    }
}
