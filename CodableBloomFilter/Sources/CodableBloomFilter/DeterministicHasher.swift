// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum DeterministicHasher: String, Codable {
    case djb2
    case djb2a
    case sdbm
    case fnv1
    case fnv1a
}

extension DeterministicHasher {
    func apply(_ hashable: DeterministicallyHashable) -> Int {
        Int(Array(hashable.hashableData)
            .map(UInt32.init)
            .reduce(offsetBasis, hash))
    }
}

// http://www.cse.yorku.ca/~oz/hash.html
// http://www.isthe.com/chongo/tech/comp/fnv/

private extension DeterministicHasher {
    static let fnvPrime: UInt32 = 16777619

    var offsetBasis: UInt32 {
        switch self {
        case .djb2, .djb2a: return 5381
        case .sdbm: return 0
        case .fnv1, .fnv1a: return 2166136261
        }
    }

    func hash(result: UInt32, next: UInt32) -> UInt32 {
        switch self {
        case .djb2:
            return (result << 5) &+ result &+ next
        case .djb2a:
            return (result << 5) &+ result ^ next
        case .sdbm:
            return next &+ (result << 6) &+ (result << 16) &- result
        case .fnv1:
            return (result &* Self.fnvPrime) ^ next
        case .fnv1a:
            return (result ^ next) &* Self.fnvPrime
        }
    }
}
