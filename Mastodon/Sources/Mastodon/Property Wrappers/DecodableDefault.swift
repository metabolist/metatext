// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol DecodableDefaultSource {
    associatedtype Value: Decodable
    static var defaultValue: Value { get }
}

public enum DecodableDefault {}

// swiftlint:disable nesting
extension DecodableDefault {
    @propertyWrapper
    public struct Wrapper<Source: DecodableDefaultSource> {
        public typealias Value = Source.Value
        public var wrappedValue = Source.defaultValue

        public init() {}
    }
}

public extension DecodableDefault {
    typealias Source = DecodableDefaultSource
    typealias List = Decodable & ExpressibleByArrayLiteral
    typealias Map = Decodable & ExpressibleByDictionaryLiteral

    enum Sources {
        public enum True: Source {
            public static var defaultValue: Bool { true }
        }

        public enum False: Source {
            public static var defaultValue: Bool { false }
        }

        public enum EmptyString: Source {
            public static var defaultValue: String { "" }
        }

        public enum EmptyHTML: Source {
            public static var defaultValue: HTML { HTML(raw: "", attributed: NSAttributedString(string: "")) }
        }

        public enum EmptyList<T: List>: Source {
            public static var defaultValue: T { [] }
        }

        public enum EmptyMap<T: Map>: Source {
            public static var defaultValue: T { [:] }
        }

        public enum Zero: Source {
            public static var defaultValue: Int { 0 }
        }

        public enum StatusVisibilityPublic: Source {
            public static var defaultValue: Status.Visibility { .public }
        }

        public enum ExpandMediaDefault: Source {
            public static var defaultValue: Preferences.ExpandMedia { .default }
        }
    }
}
// swiftlint:enable nesting

public extension DecodableDefault {
    typealias True = Wrapper<Sources.True>
    typealias False = Wrapper<Sources.False>
    typealias EmptyString = Wrapper<Sources.EmptyString>
    typealias EmptyHTML = Wrapper<Sources.EmptyHTML>
    typealias EmptyList<T: List> = Wrapper<Sources.EmptyList<T>>
    typealias EmptyMap<T: Map> = Wrapper<Sources.EmptyMap<T>>
    typealias Zero = Wrapper<Sources.Zero>
    typealias StatusVisibilityPublic = Wrapper<Sources.StatusVisibilityPublic>
    typealias ExpandMediaDefault = Wrapper<Sources.ExpandMediaDefault>
}

extension DecodableDefault.Wrapper: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Value.self)
    }
}

extension DecodableDefault.Wrapper: Equatable where Value: Equatable {}
extension DecodableDefault.Wrapper: Hashable where Value: Hashable {}

extension DecodableDefault.Wrapper: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public extension KeyedDecodingContainer {
    func decode<T>(_ type: DecodableDefault.Wrapper<T>.Type,
                   forKey key: Key) throws -> DecodableDefault.Wrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}
