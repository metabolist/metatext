// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

protocol Unknowable: RawRepresentable, CaseIterable where RawValue: Equatable {
    static var unknown: RawValue { get }
}

extension Unknowable {
    init(rawValue: RawValue) {
        self = Self.allCases.first { $0.rawValue == rawValue } ?? Self(rawValue: Self.unknown)
    }
}

extension Unknowable where RawValue == String {
    static var unknown: String { "unknown" }
}
