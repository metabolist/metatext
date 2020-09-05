// Copyright © 2020 Metabolist. All rights reserved.

// Adapted from https://github.com/dduan/BitArray

import Foundation

struct BitArray {
    let count: Int

    private var items: [UInt8]

    init(count: Int) {
        self.count = count

        var (byteCount, bitRemainder) = count.quotientAndRemainder(dividingBy: Self.bitsInByte)

        byteCount += bitRemainder > 0 ? 1 : 0

        items = [UInt8](repeating: 0, count: byteCount)
    }

    init(data: Data, count: Int) {
        self.items = Array(data)
        self.count = count
    }
}

extension BitArray {
    var data: Data { Data(items) }

    subscript(index: Int) -> Bool {
        get {
            let (byteCount, bitPosition) = index.quotientAndRemainder(dividingBy: Self.bitsInByte)

            return items[byteCount] & mask(index: bitPosition) > 0
        }

        set {
            let (byteCount, bitPosition) = index.quotientAndRemainder(dividingBy: Self.bitsInByte)

            if newValue {
                items[byteCount] |= mask(index: bitPosition)
            } else {
                items[byteCount] &= ~mask(index: bitPosition)
            }
        }
    }
}

private extension BitArray {
    static let bitsInByte = 8

    func mask(index: Int) -> UInt8 {
        switch index {
        case 0: return 0b00000001
        case 1: return 0b00000010
        case 2: return 0b00000100
        case 3: return 0b00001000
        case 4: return 0b00010000
        case 5: return 0b00100000
        case 6: return 0b01000000
        case 7: return 0b10000000
        default:
            fatalError("Invalid index: \(index)")
        }
    }
}
