// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class AnnouncementViewModel: ObservableObject {
    public let identityContext: IdentityContext

    private let announcementService: AnnouncementService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    init(announcementService: AnnouncementService,
         identityContext: IdentityContext,
         eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>) {
        self.announcementService = announcementService
        self.identityContext = identityContext
        self.eventsSubject = eventsSubject
    }
}

public extension AnnouncementViewModel {
    var announcement: Announcement { announcementService.announcement }
}

public extension AnnouncementViewModel {
    func urlSelected(_ url: URL) {
        eventsSubject.send(
            announcementService.navigationService.item(url: url)
                .map { .navigation($0) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }

    func dismissIfUnread() {
        guard !announcement.read else { return }

        eventsSubject.send(
            announcementService.dismiss()
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func reload() {
        eventsSubject.send(Just(.reload(.announcement(announcementService.announcement)))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher())
    }

    func addReaction(name: String) {
        eventsSubject.send(
            announcementService.addReaction(name: name)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func removeReaction(name: String) {
        eventsSubject.send(
            announcementService.removeReaction(name: name)
                .map { _ in .ignorableOutput }
                .eraseToAnyPublisher())
    }

    func presentEmojiPicker(sourceViewTag: Int) {
        eventsSubject.send(Just(.presentEmojiPicker(
                                    sourceViewTag: sourceViewTag,
                                    selectionAction: { [weak self] in self?.addReaction(name: $0) }))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher())
    }
}
