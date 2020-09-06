// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// https://en.wikipedia.org/wiki/Bloom_filter
// https://khanlou.com/2018/09/bloom-filters/
// This implementation uses deterministic hashing functions so it can be serialized / deserialized

public struct BloomFilter<T: DeterministicallyHashable> {
    public let hashers: [DeterministicHasher]
    public let bits: Int

    private var data: BitArray

    public init(hashes: [DeterministicHasher], bits: Int) {
        self.hashers = hashes
        self.bits = bits
        data = BitArray(count: bits)
    }
}

public extension BloomFilter {
    mutating func insert(_ newMember: T) {
        for index in indices(newMember) {
            data[index] = true
        }
    }

    func contains(_ member: T) -> Bool {
        indices(member).map { data[$0] }.allSatisfy { $0 }
    }
}

extension BloomFilter: Codable {
    private enum CodingKeys: String, CodingKey {
        case hashers
        case bits
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hashers = try container.decode([DeterministicHasher].self, forKey: .hashers)
        bits = try container.decode(Int.self, forKey: .bits)
        data = BitArray(data: try container.decode(Data.self, forKey: .data), count: bits)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hashers, forKey: .hashers)
        try container.encode(bits, forKey: .bits)
        try container.encode(data.data, forKey: .data)
    }
}

private extension BloomFilter {
    func indices(_ member: T) -> [Int] {
        hashers.map { abs($0.apply(member)) % bits }
    }
}
