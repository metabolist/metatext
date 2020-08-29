// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum FilterEndpoint {
    case create(
            phrase: String,
            context: [Filter.Context],
            irreversible: Bool,
            wholeWord: Bool,
            expiresIn: Date?)
    case update(
            id: String,
            phrase: String,
            context: [Filter.Context],
            irreversible: Bool,
            wholeWord: Bool,
            expiresIn: Date?)
}

extension FilterEndpoint: MastodonEndpoint {
    typealias ResultType = Filter

    var context: [String] {
        defaultContext + ["filters"]
    }

    var pathComponentsInContext: [String] {
        switch self {
        case .create:
            return []
        case let .update(id, _, _, _, _, _):
            return [id]
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .create(phrase, context, irreversible, wholeWord, expiresIn):
            return params(phrase: phrase,
                          context: context,
                          irreversible: irreversible,
                          wholeWord: wholeWord,
                          expiresIn: expiresIn)
        case let .update(id, phrase, context, irreversible, wholeWord, expiresIn):
            var params = self.params(phrase: phrase,
                                     context: context,
                                     irreversible: irreversible,
                                     wholeWord: wholeWord,
                                     expiresIn: expiresIn)

            params["id"] = id

            return params
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .update:
            return .put
        }
    }
}

private extension FilterEndpoint {
    func params(phrase: String,
                context: [Filter.Context],
                irreversible: Bool,
                wholeWord: Bool,
                expiresIn: Date?) -> [String: Any] {
        var params: [String: Any] = [
            "phrase": phrase,
            "context": context.map(\.rawValue),
            "irreversible": irreversible,
            "whole_word": wholeWord]

        if let expiresIn = expiresIn {
            params["expires_in"] = Self.dateFormatter.string(from: expiresIn)
        }

        return params
    }

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = MastodonAPI.dateFormat

        return dateFormatter
    }()
}
