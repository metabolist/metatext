// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct BitArray {
    private var bytes: [UInt8]

    init(data: Data) {
        bytes = Array(data)
    }
}

extension BitArray {
    var bitCount: Int { bytes.count * Self.bitsInByte }

    var data: Data { Data(bytes) }

    subscript(index: Int) -> Bool {
        get {
            let (byteIndex, bitIndex) = index.quotientAndRemainder(dividingBy: Self.bitsInByte)

            return bytes[byteIndex] & Self.mask(bitIndex: bitIndex) > 0
        }

        set {
            let (byteIndex, bitIndex) = index.quotientAndRemainder(dividingBy: Self.bitsInByte)

            if newValue {
                bytes[byteIndex] |= Self.mask(bitIndex: bitIndex)
            } else {
                bytes[byteIndex] &= ~Self.mask(bitIndex: bitIndex)
            }
        }
    }
}

extension BitArray: Codable {
    init(from decoder: Decoder) throws {
        bytes = Array(try decoder.singleValueContainer().decode(Data.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(Data(bytes))
    }
}

private extension BitArray {
    static let bitsInByte = 8

    static func mask(bitIndex: Int) -> UInt8 {
        UInt8(2 << (bitIndex - 1))
    }
}
