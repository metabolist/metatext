// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum StubData {}

public extension StubData {
    // swiftlint:disable force_try
    static let account = try! Data(contentsOf: Bundle.module.url(forResource: "account",
                                                                 withExtension: "json")!)
    static let instance = try! Data(contentsOf: Bundle.module.url(forResource: "instance",
                                                                  withExtension: "json")!)
    static let preferences = try! Data(contentsOf: Bundle.module.url(forResource: "preferences",
                                                                     withExtension: "json")!)
    static let timeline = try! Data(contentsOf: Bundle.module.url(forResource: "timeline",
                                                                  withExtension: "json")!)
    // swiftlint:enable force_try
}
