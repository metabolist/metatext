// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum MediaProcessingError: Error {
    case invalidMimeType
    case fileURLNotFound
    case unsupportedType
    case unableToCreateImageSource
    case unableToDownsample
    case unableToCreateImageDataDestination
}

public struct MediaProcessingService {}

public extension MediaProcessingService {
    static func dataAndMimeType(itemProvider: NSItemProvider) -> AnyPublisher<(data: Data, mimeType: String), Error> {
        let registeredTypes = itemProvider.registeredTypeIdentifiers.compactMap(UTType.init)

        guard let uniformType = registeredTypes.first(where: {
            guard let mimeType = $0.preferredMIMEType else { return false }

            return Self.uploadableMimeTypes.contains(mimeType)
        }),
              let mimeType = uniformType.preferredMIMEType else {
            return Fail(error: MediaProcessingError.invalidMimeType).eraseToAnyPublisher()
        }

        return Future<Data, Error> { promise in
            itemProvider.loadFileRepresentation(forTypeIdentifier: uniformType.identifier) { url, error in
                if let error = error {
                    promise(.failure(error))
                } else if let url = url {
                    if uniformType.conforms(to: .image) {
                        promise(imageData(url: url, type: uniformType))
                    } else {
                        promise(Result { try Data(contentsOf: url) })
                    }
                } else {
                    promise(.failure(MediaProcessingError.fileURLNotFound))
                }
            }
        }
        .map { (data: $0, mimeType: mimeType) }
        .eraseToAnyPublisher()
    }
}

private extension MediaProcessingService {

    static let uploadableMimeTypes = Set(
        [UTType.png,
         UTType.jpeg,
         UTType.gif,
         UTType.webP,
         UTType.mpeg4Movie,
         UTType.quickTimeMovie,
         UTType.mp3,
         UTType.wav]
            .compactMap(\.preferredMIMEType))
    static let imageSourceOptions =  [kCGImageSourceShouldCache: false] as CFDictionary
    static let thumbnailOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: 1280
    ] as CFDictionary

    static func imageData(url: URL, type: UTType) -> Result<Data, Error> {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, Self.imageSourceOptions) else {
            return .failure(MediaProcessingError.unableToCreateImageSource)
        }

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return .failure(MediaProcessingError.unableToDownsample)
        }

        let data = NSMutableData()

        guard let imageDestination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            return .failure(MediaProcessingError.unableToCreateImageDataDestination)
        }

        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)

        return .success(data as Data)
    }
}
