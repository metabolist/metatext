// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// https://en.wikipedia.org/wiki/Bloom_filter
// https://khanlou.com/2018/09/bloom-filters/
// This implementation uses deterministic hashing functions so it can be serialized / deserialized

struct BloomFilter {
    let hashes: [Hash]
    let bitCount: Int

    private var bits: Bits

    init(hashes: [Hash], bitCount: Int) {
        self.hashes = hashes
        self.bitCount = bitCount
        bits = Bits(count: bitCount)
    }
}

extension BloomFilter {
    enum Hash: String, Codable {
        case djb2
        case sdbm
    }

    mutating func insert(_ newMember: String) {
        for index in indices(newMember) {
            bits[index] = true
        }
    }

    func contains(_ member: String) -> Bool {
        indices(member).map { bits[$0] }.allSatisfy { $0 }
    }
}

extension BloomFilter: Codable {
    enum CodingKeys: String, CodingKey {
        case hashes
        case bitCount
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .data)

        hashes = try container.decode([Hash].self, forKey: .hashes)
        bitCount = try container.decode(Int.self, forKey: .bitCount)
        bits = Bits(bytes: Array(data), count: bitCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hashes, forKey: .hashes)
        try container.encode(bitCount, forKey: .bitCount)
        try container.encode(bits.data, forKey: .data)
    }
}

private extension BloomFilter {
    func indices(_ string: String) -> [Int] {
        hashes.map { abs($0.apply(string)) % bitCount }
    }
}

// https://gist.github.com/kharrison/2355182ac03b481921073c5cf6d77a73

private extension BloomFilter.Hash {
    func apply(_ string: String) -> Int {
        string.unicodeScalars.map(\.value).reduce(initial, then)
    }

    var initial: Int {
        switch self {
        case .djb2: return 5381
        case .sdbm: return 0
        }
    }

    func then(result: Int, next: UInt32) -> Int {
        switch self {
        case .djb2:
            return (result << 5) &+ result &+ Int(next)
        case .sdbm:
            return Int(next) &+ (result << 6) &+ (result << 16) - result
        }
    }
}
