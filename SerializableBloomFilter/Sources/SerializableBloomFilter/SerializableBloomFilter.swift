// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

// https://en.wikipedia.org/wiki/Bloom_filter
// https://khanlou.com/2018/09/bloom-filters/
// This implementation uses deterministic hashing functions so it can be serialized / deserialized

struct SerializableBloomFilter {
    private var items: Bits

    init() {
        items = Bits(count: Self.itemCount)
    }

    init(serialization: Data) throws {
        items = Bits(bytes: Array(serialization), count: Self.itemCount)
    }
}

extension SerializableBloomFilter {
    var serialization: Data { items.data }

    mutating func insert(_ newMember: String) {
        for index in Self.indices(newMember) {
            items[index] = true
        }
    }

    func contains(_ member: String) -> Bool {
        Self.indices(member).map { items[$0] }.allSatisfy { $0 }
    }
}

private extension SerializableBloomFilter {
    static let itemCount = 1024
    static let hashFunctions = [djb2, sdbm]

    static func indices(_ string: String) -> [Int] {
        hashFunctions.map { abs($0(string)) % itemCount }
    }
}

// https://gist.github.com/kharrison/2355182ac03b481921073c5cf6d77a73

private func djb2(_ string: String) -> Int {
    string.unicodeScalars.map(\.value).reduce(5381) {
        ($0 << 5) &+ $0 &+ Int($1)
    }
}

private func sdbm(_ string: String) -> Int {
    string.unicodeScalars.map(\.value).reduce(0) {
        Int($1) &+ ($0 << 6) &+ ($0 << 16) - $0
    }
}
