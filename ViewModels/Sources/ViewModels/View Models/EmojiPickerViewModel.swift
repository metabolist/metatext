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
    public let identityContext: IdentityContext

    private let emojiPickerService: EmojiPickerService
    @Published private var customEmoji = [PickerEmoji.Category: [PickerEmoji]]()
    @Published private var systemEmoji = [PickerEmoji.Category: [PickerEmoji]]()
    @Published private var emojiUses = [EmojiUse]()
    @Published private var systemEmojiAnnotationsAndTags = [String: String]()
    private var cancellables = Set<AnyCancellable>()

    // swiftlint:disable:next function_body_length
    public init(identityContext: IdentityContext, queryOnly: Bool = false) {
        self.identityContext = identityContext
        emojiPickerService = identityContext.service.emojiPickerService()

        emojiPickerService.customEmojiPublisher()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$customEmoji)

        emojiPickerService.systemEmojiPublisher()
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$systemEmoji)

        emojiPickerService.emojiUses(limit: Self.frequentlyUsedLimit)
            .receive(on: DispatchQueue.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$emojiUses)

        $locale.map { $0.languageCodeWithScriptIfNecessary ?? Locale.fallbackLanguageCode }
            .removeDuplicates()
            .flatMap(emojiPickerService.systemEmojiAnnotationsAndTagsPublisher(languageCode:))
            .replaceError(with: [:])
            .assign(to: &$systemEmojiAnnotationsAndTags)

        $customEmoji.dropFirst().combineLatest(
            $systemEmoji.dropFirst(),
            $query,
            $locale.combineLatest($systemEmojiAnnotationsAndTags, $emojiUses.dropFirst()))
            .map {
                let (customEmoji, systemEmoji, query, (locale, systemEmojiAnnotationsAndTags, emojiUses)) = $0
                var emojis = customEmoji.merging(systemEmoji) { $1 }

                if !query.isEmpty {
                    let matchingSystemEmojis = Set(systemEmojiAnnotationsAndTags.filter {
                        $0.key.matches(query: query, locale: locale)
                    }.values)

                    emojis = emojis.mapValues {
                        $0.filter {
                            if $0.system {
                                return matchingSystemEmojis.contains($0.name)
                            } else {
                                return $0.name.matches(query: query, locale: locale)
                            }
                        }
                    }
                } else if queryOnly {
                    return [:]
                }

                if !queryOnly {
                    emojis[.frequentlyUsed] = emojiUses.compactMap { use in
                        emojis.values.reduce([], +)
                            .first { use.system == $0.system && use.emoji == $0.name }
                            .map(\.inFrequentlyUsed)
                    }
                }

                return emojis.filter { !$0.value.isEmpty }
            }
            .assign(to: &$emoji)
    }
}

public extension EmojiPickerViewModel {
    func updateUse(emoji: PickerEmoji) {
        emojiPickerService.updateUse(emoji: emoji)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
    }
}

private extension EmojiPickerViewModel {
    static let frequentlyUsedLimit = 12
}

private extension String {
    func matches(query: String, locale: Locale) -> Bool {
        lowercased(with: locale)
            .folding(options: .diacriticInsensitive, locale: locale)
            .contains(query.lowercased(with: locale)
                        .folding(options: .diacriticInsensitive, locale: locale))
    }
}
