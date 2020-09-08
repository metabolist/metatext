// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum Hash: String, Codable {
    case djb232
    case djb2a32
    case sdbm32
    case fnv132
    case fnv1a32
}

extension Hash {
    func apply(_ hashable: DeterministicallyHashable) -> Int {
        Int(Array(hashable.dataForHashingDeterministically)
            .map(UInt32.init)
            .reduce(offsetBasis, hash))
    }
}

// http://www.cse.yorku.ca/~oz/hash.html
// http://www.isthe.com/chongo/tech/comp/fnv/

private extension Hash {
    static let fnvPrime: UInt32 = 16777619

    var offsetBasis: UInt32 {
        switch self {
        case .djb232, .djb2a32: return 5381
        case .sdbm32: return 0
        case .fnv132, .fnv1a32: return 2166136261
        }
    }

    func hash(result: UInt32, next: UInt32) -> UInt32 {
        switch self {
        case .djb232:
            return (result << 5) &+ result &+ next
        case .djb2a32:
            return (result << 5) &+ result ^ next
        case .sdbm32:
            return next &+ (result << 6) &+ (result << 16) &- result
        case .fnv132:
            return (result &* Self.fnvPrime) ^ next
        case .fnv1a32:
            return (result ^ next) &* Self.fnvPrime
        }
    }
}
