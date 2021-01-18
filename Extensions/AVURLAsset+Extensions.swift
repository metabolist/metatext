// Copyright © 2021 Metabolist. All rights reserved.

import AVFoundation

enum AssetExportError: Error {
    case exportSetup
    case export
}

extension AVURLAsset {
    func exportWithoutAudioTrack(completion: @escaping ((Result<URL, AssetExportError>) -> Void)) {
        let composition = AVMutableComposition()
        let exportDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        guard let sourceVideoTrack = tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid),
              case .success = Result(catching: {
                try compositionVideoTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: sourceVideoTrack, at: .zero)
              }),
              let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality),
              exportSession.supportedFileTypes.contains(.mp4),
              case .success = Result(catching: {
                try FileManager.default.createDirectory(
                    at: exportDirectory,
                    withIntermediateDirectories: false)
              })
        else {
            completion(.failure(.exportSetup))

            return
        }

        let exportURL = exportDirectory.appendingPathComponent(url.lastPathComponent)

        exportSession.outputFileType = AVFileType.mp4
        exportSession.outputURL = exportURL
        exportSession.timeRange = CMTimeRange(start: .zero, duration: duration)
        exportSession.exportAsynchronously {
            guard exportSession.status == .completed else {
                completion(.failure(.export))

                return
            }

            completion(.success(exportURL))
        }
    }
}
