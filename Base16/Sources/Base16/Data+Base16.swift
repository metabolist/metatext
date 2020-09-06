// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum Base16EncodingError: Error {
    case invalidLength
    case invalidByteString(String)
    case invalidStringEncoding
}

public extension Data {
    enum Base16EncodingOptions {
        case uppercase
    }

    func base16EncodedString(options: [Base16EncodingOptions] = []) -> String {
        map { String(format: Self.format(options: options), $0) }.joined()
    }

    func base16EncodedData(options: [Base16EncodingOptions] = []) -> Data {
        Data(base16EncodedString(options: options).utf8)
    }

    init(base16Encoded string: String) throws {
        let stringLength = string.count

        guard stringLength % 2 == 0 else {
            throw Base16EncodingError.invalidLength
        }

        var data = [UInt8]()

        data.reserveCapacity(stringLength / 2)

        var i = string.startIndex

        while i != string.endIndex {
            let j = string.index(i, offsetBy: 2)
            let byteString = string[i..<j]

            guard let byte = UInt8(byteString, radix: 16) else {
                throw Base16EncodingError.invalidByteString(String(byteString))
            }

            data.append(byte)
            i = j
        }

        self = Data(data)
    }

    init(base16Encoded data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Base16EncodingError.invalidStringEncoding
        }

        try self.init(base16Encoded: string)
    }
}

private extension Data {
    static let lowercaseBase16Format = "%02.2hhx"
    static let uppercaseBase16Format = "%02.2hhX"

    static func format(options: [Base16EncodingOptions]) -> String {
        options.contains(.uppercase) ? uppercaseBase16Format : lowercaseBase16Format
    }
}
