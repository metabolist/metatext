// Copyright © 2020 Metabolist. All rights reserved.

// Adapted from https://github.com/dduan/BitArray

import Foundation

struct BitArray {
    private var bytes: [UInt8]

    init(byteCount: Int) {
        self.bytes = [UInt8](repeating: 0, count: byteCount)
    }

    init(data: Data) {
        bytes = Array(data)
    }
}

extension BitArray {
    var bitCount: Int { bytes.count * Self.bitsInByte }

    subscript(index: Int) -> Bool {
        get {
            let (byteIndex, bitIndex) = Self.byteAndBitIndices(index: index)

            return bytes[byteIndex] & Self.mask(bitIndex: bitIndex) > 0
        }

        set {
            let (byteIndex, bitIndex) = Self.byteAndBitIndices(index: index)

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
        let container = try decoder.singleValueContainer()

        bytes = Array(try container.decode(Data.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(Data(bytes))
    }
}

private extension BitArray {
    static let bitsInByte = 8

    static func byteAndBitIndices(index: Int) -> (Int, Int) {
        index.quotientAndRemainder(dividingBy: bitsInByte)
    }

    static func mask(bitIndex: Int) -> UInt8 {
        switch bitIndex {
        case 0: return 0b00000001
        case 1: return 0b00000010
        case 2: return 0b00000100
        case 3: return 0b00001000
        case 4: return 0b00010000
        case 5: return 0b00100000
        case 6: return 0b01000000
        case 7: return 0b10000000
        default:
            fatalError("Invalid bit index: \(bitIndex)")
        }
    }
}
