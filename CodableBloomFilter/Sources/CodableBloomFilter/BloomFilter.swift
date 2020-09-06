// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// https://en.wikipedia.org/wiki/Bloom_filter
// https://khanlou.com/2018/09/bloom-filters/
// This implementation uses deterministic hashing functions so it can conform to Codable

public struct BloomFilter<T: DeterministicallyHashable>: Codable {
    public let hashers: [DeterministicHasher]

    private var data: BitArray

    public init(hashers: [DeterministicHasher], byteCount: Int) {
        self.hashers = hashers
        data = BitArray(byteCount: byteCount)
    }
}

public extension BloomFilter {
    mutating func insert(_ newMember: T) {
        for index in indices(newMember) {
            data[index] = true
        }
    }

    func contains(_ member: T) -> Bool {
        indices(member).allSatisfy { data[$0] }
    }
}

private extension BloomFilter {
    func indices(_ member: T) -> [Int] {
        hashers.map { abs($0.apply(member)) % data.bitCount }
    }
}
