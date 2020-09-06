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
        Array(hashable.hashableData)
            .map(Int.init)
            .reduce(offsetBasis, hash)
    }
}

// http://www.cse.yorku.ca/~oz/hash.html
// http://www.isthe.com/chongo/tech/comp/fnv/

private extension DeterministicHasher {
    static let fnvPrime = 16777619
    static let u32mod = 2 << 31

    var offsetBasis: Int {
        switch self {
        case .djb2, .djb2a: return 5381
        case .sdbm: return 0
        case .fnv1, .fnv1a: return 2166136261
        }
    }

    func hash(result: Int, next: Int) -> Int {
        switch self {
        case .djb2:
            return (result << 5) &+ result &+ next
        case .djb2a:
            return ((result << 5) &+ result ^ next) % Self.u32mod
        case .sdbm:
            return next &+ (result << 6) &+ (result << 16) &- result
        case .fnv1:
            return (result * Self.fnvPrime % Self.u32mod) ^ next
        case .fnv1a:
            return (result ^ next) * Self.fnvPrime % Self.u32mod
        }
    }
}
