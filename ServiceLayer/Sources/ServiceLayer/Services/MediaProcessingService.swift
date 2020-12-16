// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ImageIO
import Mastodon
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
    static func attachment(itemProvider: NSItemProvider) -> AnyPublisher<Composition.Attachment, Error> {
        let registeredTypes = itemProvider.registeredTypeIdentifiers.compactMap(UTType.init)

        guard let uniformType = registeredTypes.first(where: {
            guard let mimeType = $0.preferredMIMEType else { return false }

            return !Self.unuploadableMimeTypes.contains(mimeType)
        }),
              let mimeType = uniformType.preferredMIMEType else {
            return Fail(error: MediaProcessingError.invalidMimeType).eraseToAnyPublisher()
        }

        let type: Attachment.AttachmentType

        if uniformType.conforms(to: .image) {
            type = .image
        } else if uniformType.conforms(to: .movie) {
            type = .video
        } else if uniformType.conforms(to: .audio) {
            type = .audio
        } else if uniformType.conforms(to: .video), uniformType == .mpeg4Movie {
            type = .gifv
        } else {
            type = .unknown
        }

        return Future<Data, Error> { promise in
            itemProvider.loadFileRepresentation(forTypeIdentifier: uniformType.identifier) { url, error in
                if let error = error {
                    return promise(.failure(error))
                }

                guard let url = url else { return promise(.failure(MediaProcessingError.fileURLNotFound)) }

                if uniformType.conforms(to: .image) {
                    return promise(imageData(url: url, type: uniformType))
                } else {
                    do {
                        return try promise(.success(Data(contentsOf: url)))
                    } catch {
                        return promise(.failure(error))
                    }
                }
            }
        }
        .map { Composition.Attachment(data: $0, type: type, mimeType: mimeType) }
        .eraseToAnyPublisher()
    }
}

private extension MediaProcessingService {
    static let unuploadableMimeTypes: Set<String> = [UTType.heic.preferredMIMEType!]
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
