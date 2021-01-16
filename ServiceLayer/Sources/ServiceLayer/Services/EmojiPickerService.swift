// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon

public enum EmojiPickerError: Error {
    case invalidLocaleLanguageCode
    case emojisFileMissing
    case invalidSystemEmojiGroup
    case annotationsAndTagsFileMissing
}

public struct EmojiPickerService {
    private let contentDatabase: ContentDatabase

    init(contentDatabase: ContentDatabase) {
        self.contentDatabase = contentDatabase
    }
}

public extension EmojiPickerService {
    func customEmojiPublisher() -> AnyPublisher<[PickerEmoji.Category: [PickerEmoji]], Error> {
        contentDatabase.pickerEmojisPublisher().map {
            var typed = [PickerEmoji.Category: [PickerEmoji]]()

            for emoji in $0 {
                let category: PickerEmoji.Category

                if let categoryName = emoji.category {
                    category = .customNamed(categoryName)
                } else {
                    category = .custom
                }

                if typed[category] == nil {
                    typed[category] = [.custom(emoji, inFrequentlyUsed: false)]
                } else {
                    typed[category]?.append(.custom(emoji, inFrequentlyUsed: false))
                }
            }

            return typed
        }
        .eraseToAnyPublisher()
    }

    func systemEmojiPublisher() -> AnyPublisher<[PickerEmoji.Category: [PickerEmoji]], Error> {
        Future { promise in
            DispatchQueue.global(qos: .userInteractive).async {
                guard let url = Bundle.module.url(forResource: "emojis", withExtension: "json") else {
                    promise(.failure(EmojiPickerError.emojisFileMissing))

                    return
                }

                do {
                    let data = try Data(contentsOf: url)
                    let decoded = try JSONDecoder().decode([String: [SystemEmoji]].self, from: data)
                    var typed = [PickerEmoji.Category: [PickerEmoji]]()

                    for (groupString, emoji) in decoded {
                        guard let rawValue = Int(groupString),
                              let group = SystemEmoji.Group(rawValue: rawValue)
                        else {
                            promise(.failure(EmojiPickerError.invalidSystemEmojiGroup))

                            return
                        }

                        typed[.systemGroup(group)] = emoji
                            .filter { !($0.version > Self.maxEmojiVersion) }
                            .map {
                                PickerEmoji.system(
                                    $0.withMaxVersionForSkinToneVariations(Self.maxEmojiVersion),
                                    inFrequentlyUsed: false)
                            }
                    }

                    return promise(.success(typed))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func systemEmojiAnnotationsAndTagsPublisher(locale: Locale) -> AnyPublisher<[String: String], Error> {
        Future { promise in
            guard let languageCode = locale.languageCode else {
                promise(.failure(EmojiPickerError.invalidLocaleLanguageCode))

                return
            }

            let language: String

            if languageCode == "zh" && locale.scriptCode == "Hant" {
                language = "zh_Hant"
            } else {
                language = languageCode
            }

            guard let url = Bundle.module.url(forResource: language, withExtension: "json") else {
                promise(.failure(EmojiPickerError.annotationsAndTagsFileMissing))

                return
            }

            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([String: String].self, from: data)

                promise(.success(decoded))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func emojiUses(limit: Int) -> AnyPublisher<[EmojiUse], Error> {
        contentDatabase.emojiUses(limit: limit)
    }

    func updateUse(emoji: PickerEmoji) -> AnyPublisher<Never, Error> {
        contentDatabase.updateUse(emoji: emoji.name, system: emoji.system)
    }
}

private extension EmojiPickerService {
    static var maxEmojiVersion: Float = {
        if #available(iOS 14.2, *) {
            return 13.0
        }

        return 12.1
    }()
}
