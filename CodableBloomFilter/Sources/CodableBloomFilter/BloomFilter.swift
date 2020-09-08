// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// https://en.wikipedia.org/wiki/Bloom_filter
// https://khanlou.com/2018/09/bloom-filters/
// This implementation uses deterministic hashing functions so it can conform to Codable

enum BloomFilterError: Error {
    case noHashesProvided
}

public struct BloomFilter<T: DeterministicallyHashable>: Codable {
    enum CodingKeys: String, CodingKey {
        case hashes
        case bits = "data"
    }

    public let hashes: [Hash]

    private var bits: BitArray

    public init(hashes: Set<Hash>, byteCount: Int) throws {
        try self.init(hashes: hashes, data: Data(repeating: 0, count: byteCount))
    }

    public init(hashes: Set<Hash>, data: Data) throws {
        guard !hashes.isEmpty else { throw BloomFilterError.noHashesProvided }
        // Sort the hashes for consistent decoding output
        self.hashes = Array(hashes.sorted { $0.rawValue < $1.rawValue })
        bits = BitArray(data: data)
    }
}

public extension BloomFilter {
    var data: Data { bits.data }

    mutating func insert(_ newMember: T) {
        for index in indices(newMember) {
            bits[index] = true
        }
    }

    func contains(_ member: T) -> Bool {
        indices(member).allSatisfy { bits[$0] }
    }
}

private extension BloomFilter {
    func indices(_ member: T) -> [Int] {
        hashes.map { abs($0.apply(member)) % bits.bitCount }
    }
}
