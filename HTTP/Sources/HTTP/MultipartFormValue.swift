// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum MultipartFormValue {
    case string(String)
    case data(Data, filename: String, mimeType: String)
}

extension MultipartFormValue {
    func httpBodyComponent(boundary: String, key: String) -> Data {
        switch self {
        case let .string(value):
            return Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".utf8)
        case let .data(data, filename, mimeType):
            var component = Data()

            component.append(Data("--\(boundary)\r\n".utf8))
            component.append(Data("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".utf8))
            component.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
            component.append(data)
            component.append(Data("\r\n".utf8))

            return component
        }
    }
}
