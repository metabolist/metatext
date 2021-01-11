// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

final class XMLUnescaper: NSObject {
    private let rawString: String
    private let parser: XMLParser
    private var unescaped = ""
    private static let containerTag = "com.metabolist.metatext.container-tag"
    private static let openingContainerTag = "<\(containerTag)>"
    private static let closingContainerTag = "</\(containerTag)>"

    init(string: String) {
        rawString = Self.openingContainerTag
            .appending(string)
            .appending(Self.closingContainerTag)
        parser = XMLParser(data: Data(rawString.utf8))

        super.init()

        parser.delegate = self
    }
}

extension XMLUnescaper {
    func unescape() -> String {
        parser.parse()

        return unescaped
    }
}

extension XMLUnescaper: XMLParserDelegate {
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        unescaped.append(string)
    }
}
