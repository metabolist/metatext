// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol Unknowable: RawRepresentable, CaseIterable where RawValue: Equatable {
    static var unknownCase: Self { get }
}

public extension Unknowable {
    init(rawValue: RawValue) {
        self = Self.allCases.first { $0.rawValue == rawValue } ?? Self.unknownCase
    }

    static var allCasesExceptUnknown: [Self] { allCases.filter { $0 != unknownCase } }
}
