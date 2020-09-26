// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct BitArray {
    private var bytes: [UInt8]

    init(data: Data) {
        bytes = Array(data)
    }
}

extension BitArray {
    var bitCount: Int { bytes.count * UInt8.bitWidth }

    var data: Data { Data(bytes) }

    subscript(index: Int) -> Bool {
        get {
            let (byteIndex, mask) = Self.byteIndexAndMask(index: index)

            return bytes[byteIndex] & mask > 0
        }

        set {
            let (byteIndex, mask) = Self.byteIndexAndMask(index: index)

            if newValue {
                bytes[byteIndex] |= mask
            } else {
                bytes[byteIndex] &= ~mask
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
    static func byteIndexAndMask(index: Int) -> (Int, UInt8) {
        let (byteIndex, bitIndex) = index.quotientAndRemainder(dividingBy: UInt8.bitWidth)
        let mask = UInt8(2 << (bitIndex - 1))

        return (byteIndex, mask)
    }
}
