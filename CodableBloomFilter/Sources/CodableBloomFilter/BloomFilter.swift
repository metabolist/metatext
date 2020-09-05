// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// https://en.wikipedia.org/wiki/Bloom_filter
// https://khanlou.com/2018/09/bloom-filters/
// This implementation uses deterministic hashing functions so it can be serialized / deserialized

public struct BloomFilter<T: DeterministicallyHashable> {
    public let hashes: [Hash]
    public let bits: Int

    private var data: BitArray

    public init(hashes: [Hash], bits: Int) {
        self.hashes = hashes
        self.bits = bits
        data = BitArray(count: bits)
    }
}

public extension BloomFilter {
    enum Hash: String, Codable {
        case djb2
        case sdbm
    }

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
        case hashes
        case bits
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hashes = try container.decode([Hash].self, forKey: .hashes)
        bits = try container.decode(Int.self, forKey: .bits)
        data = BitArray(data: try container.decode(Data.self, forKey: .data), count: bits)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hashes, forKey: .hashes)
        try container.encode(bits, forKey: .bits)
        try container.encode(data.data, forKey: .data)
    }
}

private extension BloomFilter {
    func indices(_ member: T) -> [Int] {
        hashes.map { abs($0.apply(member)) % bits }
    }
}

// https://gist.github.com/kharrison/2355182ac03b481921073c5cf6d77a73

private extension BloomFilter.Hash {
    func apply(_ member: T) -> Int {
        Array(member.deterministicallyHashableData)
            .map(Int.init)
            .reduce(initial, then)
    }

    var initial: Int {
        switch self {
        case .djb2: return 5381
        case .sdbm: return 0
        }
    }

    func then(result: Int, next: Int) -> Int {
        switch self {
        case .djb2:
            return (result << 5) &+ result &+ next
        case .sdbm:
            return next &+ (result << 6) &+ (result << 16) - result
        }
    }
}
