// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

final public class EmojiPickerViewModel: ObservableObject {
    @Published public var alertItem: AlertItem?
    @Published public var query = ""
    @Published public var locale = Locale.current
    @Published public private(set) var emoji = [PickerEmoji.Category: [PickerEmoji]]()

    private let identification: Identification
    private let emojiPickerService: EmojiPickerService
    @Published private var customEmoji = [PickerEmoji.Category: [PickerEmoji]]()
    @Published private var systemEmoji = [PickerEmoji.Category: [PickerEmoji]]()
    @Published private var systemEmojiAnnotationsAndTags = [String: String]()
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        emojiPickerService = identification.service.emojiPickerService()

        emojiPickerService.customEmojiPublisher()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$customEmoji)

        emojiPickerService.systemEmojiPublisher()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$systemEmoji)

        $customEmoji.dropFirst().combineLatest(
            $systemEmoji.dropFirst(),
            $query,
            $locale.combineLatest($systemEmojiAnnotationsAndTags)) // Combine API limits to 4 params
            .map {
                let (customEmoji, systemEmoji, query, (locale, systemEmojiAnnotationsAndTags)) = $0

                var queriedCustomEmoji = customEmoji
                var queriedSystemEmoji = systemEmoji

                if !query.isEmpty {
                    queriedCustomEmoji = queriedCustomEmoji.mapValues {
                        $0.filter {
                            guard case let .custom(emoji) = $0 else { return false }

                            return emoji.shortcode.matches(query: query, locale: locale)
                        }
                    }
                    queriedCustomEmoji = queriedCustomEmoji.filter { !$0.value.isEmpty }

                    let matchingSystemEmojis = Set(systemEmojiAnnotationsAndTags.filter {
                        $0.key.matches(query: query, locale: locale)
                    }.values)

                    queriedSystemEmoji = queriedSystemEmoji.mapValues {
                        $0.filter {
                            guard case let .system(emoji) = $0 else { return false }

                            return matchingSystemEmojis.contains(emoji.emoji)
                        }
                    }
                    queriedSystemEmoji = queriedSystemEmoji.filter { !$0.value.isEmpty }
                }

                return queriedSystemEmoji.merging(queriedCustomEmoji) { $1 }
            }
            .assign(to: &$emoji)

        $locale.removeDuplicates().flatMap(emojiPickerService.systemEmojiAnnotationsAndTagsPublisher(locale:))
            .replaceError(with: [:])
            .assign(to: &$systemEmojiAnnotationsAndTags)
    }
}

private extension String {
    func matches(query: String, locale: Locale) -> Bool {
        lowercased(with: locale)
            .folding(options: .diacriticInsensitive, locale: locale)
            .contains(query.lowercased(with: locale)
                        .folding(options: .diacriticInsensitive, locale: locale))
    }
}
