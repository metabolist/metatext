// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

enum MediaProcessingError: Error {
    case invalidMimeType
    case fileURLNotFound
    case unsupportedType
    case unableToCreateImageSource
    case unableToDownsample
    case unableToCreateImageDataDestination
}

public enum MediaProcessingService {}

public extension MediaProcessingService {
    static func dataAndMimeType(itemProvider: NSItemProvider) -> AnyPublisher<(data: Data, mimeType: String), Error> {
        let registeredTypes = itemProvider.registeredTypeIdentifiers.compactMap(UTType.init)

        let mimeType: String
        let dataPublisher: AnyPublisher<Data, Error>

        if let uniformType = registeredTypes.first(where: {
            guard let mimeType = $0.preferredMIMEType else { return false }

            return Self.uploadableMimeTypes.contains(mimeType)
        }), let preferredMIMEType = uniformType.preferredMIMEType {
            mimeType = preferredMIMEType
            dataPublisher = Future<Data, Error> { promise in
                itemProvider.loadFileRepresentation(forTypeIdentifier: uniformType.identifier) { url, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let url = url {
                        if uniformType.conforms(to: .image) && uniformType != .gif {
                            promise(imageData(url: url, type: uniformType))
                        } else {
                            promise(Result { try Data(contentsOf: url) })
                        }
                    } else {
                        promise(.failure(MediaProcessingError.fileURLNotFound))
                    }
                }
            }
            .eraseToAnyPublisher()
        } else if registeredTypes == [UTType.image], let pngMIMEType = UTType.png.preferredMIMEType { // screenshot
            mimeType = pngMIMEType
            dataPublisher = Future<Data, Error> { promise in
                itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let image = item as? UIImage, let data = image.pngData() {
                        do {
                            let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                                .appendingPathComponent(UUID().uuidString)

                            try data.write(to: url)

                            promise(imageData(url: url, type: .png))
                        } catch {
                            promise(.failure(error))
                        }
                    } else {
                        promise(.failure(MediaProcessingError.fileURLNotFound))
                    }
                }
            }
            .eraseToAnyPublisher()
        } else {
            return Fail(error: MediaProcessingError.invalidMimeType).eraseToAnyPublisher()
        }

        return dataPublisher.map { (data: $0, mimeType: mimeType) }.eraseToAnyPublisher()
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
