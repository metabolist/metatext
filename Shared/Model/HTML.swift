// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct HTML: Hashable {
    let raw: String
    let attributed: NSAttributedString
}

extension HTML: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let attributedStringCache = decoder.userInfo[.attributedStringCache] as? AttributedStringCache

        raw = try container.decode(String.self)

        if let attributed = attributedStringCache?.object(forKey: raw as NSString) {
            self.attributed = attributed

            return
        }

        attributed = HTMLParser(string: raw).parse()
        attributedStringCache?.setObject(attributed, forKey: raw as NSString)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(raw)
    }
}

// https://docs.joinmastodon.org/spec/activitypub/#sanitization

private class HTMLParser: NSObject {
    private struct Link: Hashable {
        let href: URL
        let location: Int
        var length = 0
    }

    private let rawString: String
    private let parser: XMLParser
    private let parseStopColumn: Int
    private var constructedString = ""
    private var attributesStack = [[String: String]]()
    private var currentLink: Link?
    private var links = Set<Link>()
    private static let containerTag = "com.metabolist.metatext.container-tag"
    private static let openingContainerTag = "<\(containerTag)>"
    private static let closingContainerTag = "</\(containerTag)>"

    init(string: String) {
        rawString = Self.openingContainerTag + string + Self.closingContainerTag
        parser = XMLParser(data: Data(rawString.utf8))
        parseStopColumn = rawString.count - Self.closingContainerTag.count

        super.init()

        parser.delegate = self
    }

    func parse() -> NSAttributedString {
        parser.parse()

        let attributedString = NSMutableAttributedString(string: constructedString)

        for link in links {
            attributedString.addAttribute(.link,
                                          value: link.href,
                                          range: .init(location: link.location, length: link.length))
        }

        return attributedString
    }
}

extension HTMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        attributesStack.append(attributeDict)

        if elementName == "a", let hrefString = attributeDict["href"], let href = URL(string: hrefString) {
            currentLink = Link(href: href, location: constructedString.count)
        } else if elementName == "br" {
            constructedString.append("\n")
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        let attributes = attributesStack.removeLast()

        if attributes["class"] == "ellipsis" {
            constructedString.append("…")
        }

        if elementName == "a", var link = currentLink {
            link.length = constructedString.count - link.location
            links.insert(link)
        } else if elementName == "p", parser.columnNumber < parseStopColumn {
            constructedString.append("\n\n")
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if attributesStack.last?["class"] != "invisible" {
            constructedString.append(string)
        }
    }
}
